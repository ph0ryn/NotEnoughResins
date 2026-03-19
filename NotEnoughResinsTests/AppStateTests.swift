import Combine
import Foundation
@testable import NotEnoughResins
import Testing

@MainActor
struct AppStateTests {
    @Test
    func minuteTickerUpdatesPresentationWithoutExtraNetworkRefresh() async {
        let initialFetchAt = Date(timeIntervalSince1970: 1_741_800_000)
        let refreshClock = ManualRefreshClock(now: initialFetchAt)
        let account = ResolvedAccount(
            accountIdV2: "12345",
            server: "os_asia",
            roleId: "987654321",
            nickname: "Traveler",
            level: 60
        )
        let preferencesStore = PreferencesStore(
            keychain: AppStateTestKeychainStore(
                initialValues: [
                    PreferencesStore.cookieStorageAccount: "account_id_v2=12345; cookie_token_v2=abcdef",
                ]
            )
        )
        let accountResolver = MockAccountResolver(result: .success(account))
        let dailyNoteService = MockDailyNoteService(
            results: [
                .success(
                    makeDailyNoteSnapshot(
                        fetchedAt: initialFetchAt,
                        currentResin: 160,
                        resinRecoveryTimeSeconds: 19_200
                    )
                ),
            ]
        )
        let minuteTicker = PassthroughSubject<Date, Never>()
        let currentDate = CurrentDateBox(value: initialFetchAt)
        let appState = AppState(
            preferencesStore: preferencesStore,
            refreshCoordinator: RefreshCoordinator(
                accountResolver: accountResolver,
                dailyNoteService: dailyNoteService,
                clock: refreshClock
            ),
            refreshEnabled: true,
            minuteTicker: minuteTicker.eraseToAnyPublisher(),
            nowProvider: { currentDate.value }
        )

        await refreshClock.waitForSleepCall(count: 1)

        let initialPresentation = appState.presentation
        let lastRefreshText = initialPresentation.lastRefreshText
        #expect(initialPresentation.panel?.hero.value == "160 / 200")
        #expect(initialPresentation.panel?.hero.detail == "Full in 05:20")
        #expect(lastRefreshText != nil)
        #expect(accountResolver.cookies.count == 1)
        #expect(dailyNoteService.requests.count == 1)

        currentDate.value = initialFetchAt.addingTimeInterval(60)
        minuteTicker.send(currentDate.value)
        await Task.yield()

        let minutePresentation = appState.presentation
        #expect(minutePresentation.panel?.hero.value == "160 / 200")
        #expect(minutePresentation.panel?.hero.detail == "Full in 05:19")
        #expect(minutePresentation.lastRefreshText == lastRefreshText)
        #expect(accountResolver.cookies.count == 1)
        #expect(dailyNoteService.requests.count == 1)

        currentDate.value = initialFetchAt.addingTimeInterval(
            TimeInterval(ResinTracker.recoveryIntervalSeconds)
        )
        minuteTicker.send(currentDate.value)
        await Task.yield()

        let recoveredPresentation = appState.presentation
        #expect(recoveredPresentation.panel?.hero.value == "161 / 200")
        #expect(recoveredPresentation.panel?.hero.detail == "Full in 05:12")
        #expect(recoveredPresentation.lastRefreshText == lastRefreshText)
        #expect(accountResolver.cookies.count == 1)
        #expect(dailyNoteService.requests.count == 1)
    }

    @Test
    func savingCookieUpdatesConfigurationStateAndEnablesRefresh() async throws {
        let initialFetchAt = Date(timeIntervalSince1970: 1_741_800_000)
        let refreshClock = ManualRefreshClock(now: initialFetchAt)
        let account = ResolvedAccount(
            accountIdV2: "12345",
            server: "os_asia",
            roleId: "987654321",
            nickname: "Traveler",
            level: 60
        )
        let preferencesStore = PreferencesStore(
            keychain: AppStateTestKeychainStore(initialValues: [:])
        )
        let appState = AppState(
            preferencesStore: preferencesStore,
            refreshCoordinator: RefreshCoordinator(
                accountResolver: MockAccountResolver(result: .success(account)),
                dailyNoteService: MockDailyNoteService(
                    results: [
                        .success(
                            makeDailyNoteSnapshot(
                                fetchedAt: initialFetchAt,
                                currentResin: 160,
                                resinRecoveryTimeSeconds: 19_200
                            )
                        ),
                    ]
                ),
                clock: refreshClock
            ),
            refreshEnabled: true,
            minuteTicker: Empty<Date, Never>().eraseToAnyPublisher(),
            nowProvider: { initialFetchAt }
        )

        #expect(appState.configurationState == .needsConfiguration)
        #expect(appState.canRefreshNow == false)

        try preferencesStore.saveCookie("account_id_v2=12345; cookie_token_v2=abcdef")
        await Task.yield()

        #expect(appState.configurationState == .configurationReady)
        #expect(appState.canRefreshNow == true)
    }

    @Test
    func refreshRemainsEnabledWhileRefreshWorkIsInProgress() {
        let preferencesStore = PreferencesStore(
            keychain: AppStateTestKeychainStore(
                initialValues: [
                    PreferencesStore.cookieStorageAccount: "account_id_v2=12345; cookie_token_v2=abcdef",
                ]
            )
        )
        let appState = AppState(
            preferencesStore: preferencesStore,
            refreshCoordinator: RefreshCoordinator(
                accountResolver: MockAccountResolver(result: .failure(.authFailure)),
                dailyNoteService: MockDailyNoteService(results: []),
                clock: ManualRefreshClock(now: Date())
            ),
            refreshEnabled: true,
            minuteTicker: Empty<Date, Never>().eraseToAnyPublisher()
        )

        appState.applyDebugState(
            configurationState: .configurationReady,
            refreshPhase: .discoveringAccount,
            resolvedAccount: nil,
            latestSnapshot: nil,
            derivedResinState: nil,
            lastSuccessfulFetchAt: nil,
            trackingState: .empty
        )

        #expect(appState.canRefreshNow == true)
    }
}

private final class CurrentDateBox {
    var value: Date

    init(value: Date) {
        self.value = value
    }
}

private final class AppStateTestKeychainStore: KeychainStoring {
    private var values: [String: String]

    init(initialValues: [String: String]) {
        values = initialValues
    }

    func readString(for account: String) throws -> String? {
        values[account]
    }

    func upsertString(_ value: String, for account: String) throws {
        values[account] = value
    }
}
