import Combine
import Foundation

protocol RefreshClock {
    var now: Date { get }
    func sleep(seconds: TimeInterval) async throws
}

struct SystemRefreshClock: RefreshClock {
    nonisolated init() {}

    nonisolated var now: Date {
        Date()
    }

    nonisolated func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

@MainActor
final class RefreshCoordinator: ObservableObject {
    enum Phase: Equatable {
        case idle
        case needsConfiguration
        case discoveringAccount
        case refreshingDailyNote
        case ready
        case authError(String)
        case requestError(String)
    }

    static let refreshInterval: TimeInterval = 600

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var resolvedAccount: ResolvedAccount?
    @Published private(set) var latestSnapshot: DailyNoteSnapshot?
    @Published private(set) var lastSuccessfulFetchAt: Date?
    @Published private(set) var trackingState: ResinTrackingState = .empty

    private let accountResolver: any AccountResolving
    private let dailyNoteService: any DailyNoteFetching
    private let resinTracker: ResinTracker
    private let clock: RefreshClock
    private var refreshTask: Task<Void, Never>?

    init(
        accountResolver: any AccountResolving,
        dailyNoteService: any DailyNoteFetching,
        resinTracker: ResinTracker = ResinTracker(),
        clock: RefreshClock = SystemRefreshClock()
    ) {
        self.accountResolver = accountResolver
        self.dailyNoteService = dailyNoteService
        self.resinTracker = resinTracker
        self.clock = clock
    }

    deinit {
        refreshTask?.cancel()
    }

    static func live(httpClient: HTTPDataLoading = URLSession.shared) -> RefreshCoordinator {
        RefreshCoordinator(
            accountResolver: AccountResolver(httpClient: httpClient),
            dailyNoteService: DailyNoteService(httpClient: httpClient),
            resinTracker: ResinTracker()
        )
    }

    func start(cookie: String?) {
        beginRefreshLoop(
            cookie: cookie,
            preferResolvedAccount: false
        )
    }

    func refreshNow(cookie: String?) {
        beginRefreshLoop(
            cookie: cookie,
            preferResolvedAccount: true
        )
    }

    private func beginRefreshLoop(
        cookie: String?,
        preferResolvedAccount: Bool
    ) {
        refreshTask?.cancel()

        guard let cookie else {
            applyNeedsConfigurationState()
            return
        }

        refreshTask = Task { [weak self] in
            await self?.runRefreshLoop(
                cookie: cookie,
                preferResolvedAccount: preferResolvedAccount
            )
        }
    }

    private func runRefreshLoop(
        cookie: String,
        preferResolvedAccount: Bool
    ) async {
        do {
            let account = try await resolveAccount(
                from: cookie,
                preferResolvedAccount: preferResolvedAccount
            )
            phase = .refreshingDailyNote
            try await refreshOnce(cookie: cookie, account: account)

            while Task.isCancelled == false {
                try await clock.sleep(seconds: Self.refreshInterval)
                try Task.checkCancellation()
                phase = .refreshingDailyNote
                try await refreshOnce(cookie: cookie, account: account)
            }
        } catch is CancellationError {
            return
        } catch let error as AccountResolverError {
            apply(accountResolverError: error)
        } catch let error as DailyNoteServiceError {
            apply(dailyNoteServiceError: error)
        } catch {
            phase = .requestError(error.localizedDescription)
        }
    }

    private func resolveAccount(
        from cookie: String,
        preferResolvedAccount: Bool
    ) async throws -> ResolvedAccount {
        let cookieAccountID = CookieParser.accountIDV2(from: cookie)

        if preferResolvedAccount,
           let resolvedAccount,
           resolvedAccount.accountIdV2 == cookieAccountID
        {
            return resolvedAccount
        }

        phase = .discoveringAccount

        let account = try await accountResolver.resolveAccount(from: cookie)
        resolvedAccount = account
        return account
    }

    private func refreshOnce(cookie: String, account: ResolvedAccount) async throws {
        let snapshot = try await dailyNoteService.fetchDailyNote(
            cookie: cookie,
            account: account,
            at: clock.now
        )
        trackingState = resinTracker.updateTrackingState(
            with: snapshot,
            previousState: trackingState
        )
        latestSnapshot = snapshot
        lastSuccessfulFetchAt = snapshot.fetchedAt
        phase = .ready
    }

    func derivedResinState(at date: Date) -> DerivedResinState? {
        guard let latestSnapshot else {
            return nil
        }

        return resinTracker.derivedState(
            from: latestSnapshot,
            trackingState: trackingState,
            now: date
        )
    }

    private func apply(accountResolverError: AccountResolverError) {
        switch accountResolverError {
        case .authFailure:
            phase = .authError(accountResolverError.localizedDescription)
        default:
            phase = .requestError(accountResolverError.localizedDescription)
        }
    }

    private func apply(dailyNoteServiceError: DailyNoteServiceError) {
        switch dailyNoteServiceError {
        case .authFailure:
            phase = .authError(dailyNoteServiceError.localizedDescription)
        default:
            phase = .requestError(dailyNoteServiceError.localizedDescription)
        }
    }

    private func applyNeedsConfigurationState() {
        phase = .needsConfiguration
        resolvedAccount = nil
        latestSnapshot = nil
        lastSuccessfulFetchAt = nil
        trackingState = .empty
    }
}
