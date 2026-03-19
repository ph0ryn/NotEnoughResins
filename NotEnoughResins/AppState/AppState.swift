import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    nonisolated static let localPresentationRefreshInterval: TimeInterval = 60

    @Published private(set) var configurationState: PreferencesStore.ConfigurationState
    @Published private(set) var refreshPhase: RefreshCoordinator.Phase
    @Published private(set) var resolvedAccount: ResolvedAccount?
    @Published private(set) var latestSnapshot: DailyNoteSnapshot?
    @Published private(set) var lastSuccessfulFetchAt: Date?
    @Published private(set) var trackingState: ResinTrackingState
    @Published private var presentationTick: Date

    private let preferencesStore: PreferencesStore
    private let refreshCoordinator: RefreshCoordinator
    private let presentationBuilder = AppPresentationBuilder()
    private let refreshEnabled: Bool
    private let nowProvider: () -> Date
    private var derivedResinStateOverride: DerivedResinState?
    private var presentationDateOverride: Date?
    private var cancellables: Set<AnyCancellable> = []

    init(
        preferencesStore: PreferencesStore,
        refreshCoordinator: RefreshCoordinator,
        refreshEnabled: Bool = ProcessInfo.processInfo.environment["NOT_ENOUGH_RESINS_DISABLE_REFRESH"] != "1",
        minuteTicker: AnyPublisher<Date, Never> = AppState.makeMinuteTicker(),
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.preferencesStore = preferencesStore
        self.refreshCoordinator = refreshCoordinator
        self.refreshEnabled = refreshEnabled
        self.nowProvider = nowProvider
        configurationState = preferencesStore.configurationState
        refreshPhase = refreshCoordinator.phase
        resolvedAccount = refreshCoordinator.resolvedAccount
        latestSnapshot = refreshCoordinator.latestSnapshot
        lastSuccessfulFetchAt = refreshCoordinator.lastSuccessfulFetchAt
        trackingState = refreshCoordinator.trackingState
        presentationTick = nowProvider()
        bind(minuteTicker: minuteTicker)
        restartRefreshIfNeeded()
    }

    private nonisolated static func makeMinuteTicker() -> AnyPublisher<Date, Never> {
        Timer.publish(
            every: localPresentationRefreshInterval,
            tolerance: 5,
            on: .main,
            in: .common
        )
        .autoconnect()
        .eraseToAnyPublisher()
    }

    private func bind(minuteTicker: AnyPublisher<Date, Never>) {
        preferencesStore.$configurationState
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] configurationState in
                self?.configurationState = configurationState
            }
            .store(in: &cancellables)

        preferencesStore.$saveRevision
            .dropFirst()
            .sink { [weak self] _ in
                self?.refreshFromSavedCookie()
            }
            .store(in: &cancellables)

        refreshCoordinator.$phase
            .sink { [weak self] phase in
                self?.refreshPhase = phase
            }
            .store(in: &cancellables)

        refreshCoordinator.$resolvedAccount
            .sink { [weak self] account in
                self?.resolvedAccount = account
            }
            .store(in: &cancellables)

        refreshCoordinator.$latestSnapshot
            .sink { [weak self] snapshot in
                self?.latestSnapshot = snapshot
            }
            .store(in: &cancellables)

        refreshCoordinator.$lastSuccessfulFetchAt
            .sink { [weak self] date in
                self?.lastSuccessfulFetchAt = date
            }
            .store(in: &cancellables)

        refreshCoordinator.$trackingState
            .sink { [weak self] trackingState in
                self?.trackingState = trackingState
            }
            .store(in: &cancellables)

        minuteTicker
            .sink { [weak self] tickDate in
                self?.presentationTick = tickDate
            }
            .store(in: &cancellables)
    }

    private func restartRefreshIfNeeded() {
        guard refreshEnabled else {
            refreshPhase = .idle
            return
        }

        refreshCoordinator.start(cookie: preferencesStore.cookie)
    }

    private func refreshFromSavedCookie() {
        guard refreshEnabled else {
            refreshPhase = .idle
            return
        }

        refreshCoordinator.refreshNow(cookie: preferencesStore.cookie)
    }

    func derivedResinState(at date: Date? = nil) -> DerivedResinState? {
        let effectiveDate = date ?? currentPresentationDate()

        if let derivedResinStateOverride {
            return derivedResinStateOverride
        }

        return refreshCoordinator.derivedResinState(at: effectiveDate)
    }

    private func currentPresentationDate() -> Date {
        presentationDateOverride ?? nowProvider()
    }

    func refreshNow() {
        refreshFromSavedCookie()
    }

    var canRefreshNow: Bool {
        guard preferencesStore.cookie != nil else {
            return false
        }

        return refreshEnabled
    }

    var presentation: AppPresentation {
        let presentationDate = currentPresentationDate()

        return presentationBuilder.makePresentation(
            configurationState: configurationState,
            refreshPhase: refreshPhase,
            resolvedAccount: resolvedAccount,
            latestSnapshot: latestSnapshot,
            trackingState: trackingState,
            derivedResinState: derivedResinState(at: presentationDate),
            lastSuccessfulFetchAt: lastSuccessfulFetchAt,
            now: presentationDate
        )
    }

    #if DEBUG
        func applyDebugState(
            configurationState: PreferencesStore.ConfigurationState,
            refreshPhase: RefreshCoordinator.Phase,
            resolvedAccount: ResolvedAccount?,
            latestSnapshot: DailyNoteSnapshot?,
            derivedResinState: DerivedResinState?,
            lastSuccessfulFetchAt: Date?,
            trackingState: ResinTrackingState,
            presentationDate: Date? = nil
        ) {
            self.configurationState = configurationState
            self.refreshPhase = refreshPhase
            self.resolvedAccount = resolvedAccount
            self.latestSnapshot = latestSnapshot
            self.lastSuccessfulFetchAt = lastSuccessfulFetchAt
            self.trackingState = trackingState
            derivedResinStateOverride = derivedResinState
            presentationDateOverride = presentationDate
            if let presentationDate {
                presentationTick = presentationDate
            }
        }
    #endif
}
