import Foundation
@testable import NotEnoughResins
import Testing

@MainActor
struct RefreshCoordinatorTests {
    @Test
    func startupDiscoveryRunsOnceBeforeInitialAndScheduledRefreshes() async {
        let clock = ManualRefreshClock(now: Date(timeIntervalSince1970: 1_741_600_000))
        let account = ResolvedAccount(
            accountIdV2: "12345",
            server: "os_asia",
            roleId: "987654321",
            nickname: "Traveler",
            level: 60
        )
        let snapshots = [
            makeDailyNoteSnapshot(
                fetchedAt: clock.now,
                currentResin: 150,
                resinRecoveryTimeSeconds: 24_000
            ),
            makeDailyNoteSnapshot(
                fetchedAt: clock.now.addingTimeInterval(600),
                currentResin: 151,
                resinRecoveryTimeSeconds: 23_400,
                currentHomeCoin: 1_250,
                homeCoinRecoveryTimeSeconds: 3_000
            ),
        ]

        let accountResolver = MockAccountResolver(result: .success(account))
        let dailyNoteService = MockDailyNoteService(results: snapshots.map(Result.success))
        let coordinator = RefreshCoordinator(
            accountResolver: accountResolver,
            dailyNoteService: dailyNoteService,
            clock: clock
        )

        coordinator.start(cookie: "account_id_v2=12345; cookie_token_v2=abcdef")

        await clock.waitForSleepCall(count: 1)
        #expect(coordinator.phase == .ready)
        #expect(coordinator.resolvedAccount == account)
        #expect(coordinator.latestSnapshot?.currentResin == 150)

        #expect(accountResolver.cookies.count == 1)
        #expect(dailyNoteService.requests.count == 1)
        #expect(clock.sleepCalls == [RefreshCoordinator.refreshInterval])

        clock.advance(by: RefreshCoordinator.refreshInterval)
        await clock.waitForSleepCall(count: 2)

        #expect(accountResolver.cookies.count == 1)
        #expect(dailyNoteService.requests.count == 2)
        #expect(coordinator.latestSnapshot?.currentResin == 151)
        #expect(coordinator.trackingState.predictedFullAt == clock.now.addingTimeInterval(23_400))
    }

    @Test
    func authFailureStopsBeforePollingStarts() async {
        let coordinator = RefreshCoordinator(
            accountResolver: MockAccountResolver(result: .failure(.authFailure)),
            dailyNoteService: MockDailyNoteService(results: []),
            clock: ManualRefreshClock(now: Date())
        )

        coordinator.start(cookie: "account_id_v2=12345")
        await Task.yield()

        #expect(coordinator.phase == .authError("HoYoLAB rejected the saved cookie. Please sign in again."))
        #expect(coordinator.latestSnapshot == nil)
    }

    @Test
    func manualRefreshReusesResolvedAccountAndRefreshesImmediately() async {
        let initialFetchAt = Date(timeIntervalSince1970: 1_741_600_000)
        let clock = ManualRefreshClock(now: initialFetchAt)
        let account = ResolvedAccount(
            accountIdV2: "12345",
            server: "os_asia",
            roleId: "987654321",
            nickname: "Traveler",
            level: 60
        )
        let snapshots = [
            makeDailyNoteSnapshot(
                fetchedAt: initialFetchAt,
                currentResin: 150,
                resinRecoveryTimeSeconds: 24_000
            ),
            makeDailyNoteSnapshot(
                fetchedAt: initialFetchAt.addingTimeInterval(30),
                currentResin: 151,
                resinRecoveryTimeSeconds: 23_520
            ),
        ]

        let accountResolver = MockAccountResolver(result: .success(account))
        let dailyNoteService = MockDailyNoteService(results: snapshots.map(Result.success))
        let coordinator = RefreshCoordinator(
            accountResolver: accountResolver,
            dailyNoteService: dailyNoteService,
            clock: clock
        )

        coordinator.start(cookie: "account_id_v2=12345; cookie_token_v2=abcdef")

        await clock.waitForSleepCall(count: 1)
        #expect(coordinator.latestSnapshot?.currentResin == 150)
        #expect(accountResolver.cookies.count == 1)
        #expect(dailyNoteService.requests.count == 1)

        clock.now = initialFetchAt.addingTimeInterval(30)
        coordinator.refreshNow(cookie: "account_id_v2=12345; cookie_token_v2=abcdef")

        await clock.waitForSleepCall(count: 2)

        #expect(accountResolver.cookies.count == 1)
        #expect(dailyNoteService.requests.count == 2)
        #expect(coordinator.phase == .ready)
        #expect(coordinator.latestSnapshot?.currentResin == 151)
        #expect(coordinator.lastSuccessfulFetchAt == initialFetchAt.addingTimeInterval(30))
    }

    @Test
    func startWithoutCookieClearsInMemoryState() async {
        let initialFetchAt = Date(timeIntervalSince1970: 1_741_600_000)
        let clock = ManualRefreshClock(now: initialFetchAt)
        let account = ResolvedAccount(
            accountIdV2: "12345",
            server: "os_asia",
            roleId: "987654321",
            nickname: "Traveler",
            level: 60
        )
        let coordinator = RefreshCoordinator(
            accountResolver: MockAccountResolver(result: .success(account)),
            dailyNoteService: MockDailyNoteService(
                results: [
                    .success(
                        makeDailyNoteSnapshot(
                            fetchedAt: initialFetchAt,
                            currentResin: 150,
                            resinRecoveryTimeSeconds: 24_000
                        )
                    ),
                ]
            ),
            clock: clock
        )

        coordinator.start(cookie: "account_id_v2=12345; cookie_token_v2=abcdef")
        await clock.waitForSleepCall(count: 1)

        #expect(coordinator.latestSnapshot?.currentResin == 150)
        #expect(coordinator.phase == .ready)

        coordinator.start(cookie: nil)

        #expect(coordinator.phase == .needsConfiguration)
        #expect(coordinator.latestSnapshot == nil)
        #expect(coordinator.lastSuccessfulFetchAt == nil)
        #expect(coordinator.trackingState == .empty)
    }
}
