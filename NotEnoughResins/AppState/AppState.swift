import Combine
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var configurationState: PreferencesStore.ConfigurationState
    @Published private(set) var refreshPhase: RefreshCoordinator.Phase
    @Published private(set) var resolvedAccount: ResolvedAccount?
    @Published private(set) var latestSnapshot: DailyNoteSnapshot?
    @Published private(set) var lastSuccessfulFetchAt: Date?
    @Published private(set) var trackingState: ResinTrackingState

    private let preferencesStore: PreferencesStore
    private let refreshCoordinator: RefreshCoordinator
    private let presentationBuilder = AppPresentationBuilder()
    private let refreshEnabled: Bool
    private var derivedResinStateOverride: DerivedResinState?
    private var cancellables: Set<AnyCancellable> = []

    init(
        preferencesStore: PreferencesStore,
        refreshCoordinator: RefreshCoordinator,
        refreshEnabled: Bool = ProcessInfo.processInfo.environment["NOT_ENOUGH_RESINS_DISABLE_REFRESH"] != "1"
    ) {
        self.preferencesStore = preferencesStore
        self.refreshCoordinator = refreshCoordinator
        self.refreshEnabled = refreshEnabled
        configurationState = preferencesStore.configurationState
        refreshPhase = refreshCoordinator.phase
        resolvedAccount = refreshCoordinator.resolvedAccount
        latestSnapshot = refreshCoordinator.latestSnapshot
        lastSuccessfulFetchAt = refreshCoordinator.lastSuccessfulFetchAt
        trackingState = refreshCoordinator.trackingState
        bind()
        restartRefreshIfNeeded()
    }

    private func bind() {
        preferencesStore.$storedCookie
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else {
                    return
                }

                configurationState = preferencesStore.configurationState
                restartRefreshIfNeeded()
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
    }

    private func restartRefreshIfNeeded() {
        guard refreshEnabled else {
            refreshPhase = .idle
            return
        }

        refreshCoordinator.start(cookie: preferencesStore.cookie)
    }

    func derivedResinState(at date: Date = Date()) -> DerivedResinState? {
        if let derivedResinStateOverride {
            return derivedResinStateOverride
        }

        return refreshCoordinator.derivedResinState(at: date)
    }

    var presentation: AppPresentation {
        presentationBuilder.makePresentation(
            configurationState: configurationState,
            refreshPhase: refreshPhase,
            resolvedAccount: resolvedAccount,
            latestSnapshot: latestSnapshot,
            derivedResinState: derivedResinState(),
            lastSuccessfulFetchAt: lastSuccessfulFetchAt
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
            trackingState: ResinTrackingState
        ) {
            self.configurationState = configurationState
            self.refreshPhase = refreshPhase
            self.resolvedAccount = resolvedAccount
            self.latestSnapshot = latestSnapshot
            self.lastSuccessfulFetchAt = lastSuccessfulFetchAt
            self.trackingState = trackingState
            derivedResinStateOverride = derivedResinState
        }
    #endif
}
