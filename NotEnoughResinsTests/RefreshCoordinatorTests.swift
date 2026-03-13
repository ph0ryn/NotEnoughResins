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
        let snapshotStore = InMemorySnapshotStore()
        let coordinator = RefreshCoordinator(
            accountResolver: accountResolver,
            dailyNoteService: dailyNoteService,
            snapshotStore: snapshotStore,
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
        #expect(snapshotStore.savedRecords.count == 2)
        #expect(coordinator.trackingState.predictedFullAt == clock.now.addingTimeInterval(23_400))
    }

    @Test
    func authFailureStopsBeforePollingStarts() async {
        let coordinator = RefreshCoordinator(
            accountResolver: MockAccountResolver(result: .failure(.authFailure)),
            dailyNoteService: MockDailyNoteService(results: []),
            snapshotStore: InMemorySnapshotStore(),
            clock: ManualRefreshClock(now: Date())
        )

        coordinator.start(cookie: "account_id_v2=12345")
        await Task.yield()

        #expect(coordinator.phase == .authError("HoYoLAB rejected the saved cookie. Please sign in again."))
        #expect(coordinator.latestSnapshot == nil)
    }

    @Test
    func restoresMatchingPersistedSnapshotBeforeStartupRefresh() async {
        let restoredAt = Date(timeIntervalSince1970: 1_741_700_000)
        let snapshotStore = InMemorySnapshotStore()
        snapshotStore.storedRecord = SnapshotStoreRecord(
            accountIdV2: "12345",
            snapshot: makeDailyNoteSnapshot(
                fetchedAt: restoredAt,
                currentResin: 180,
                resinRecoveryTimeSeconds: 9_600
            ),
            trackingState: ResinTrackingState(
                lastBelowCapSnapshotAt: restoredAt,
                predictedFullAt: restoredAt.addingTimeInterval(9_600),
                overflowStartAt: nil,
                lastKnownWastedResin: nil
            )
        )

        let coordinator = RefreshCoordinator(
            accountResolver: MockAccountResolver(result: .failure(.transportFailure("stop"))),
            dailyNoteService: MockDailyNoteService(results: []),
            snapshotStore: snapshotStore,
            clock: ManualRefreshClock(now: restoredAt)
        )

        coordinator.start(cookie: "account_id_v2=12345; cookie_token_v2=abcdef")
        await Task.yield()

        #expect(coordinator.latestSnapshot?.currentResin == 180)
        #expect(coordinator.lastSuccessfulFetchAt == restoredAt)
        #expect(coordinator.trackingState.predictedFullAt == restoredAt.addingTimeInterval(9_600))
        #expect(coordinator.phase == .requestError("stop"))
    }

    @Test
    func ignoresPersistedSnapshotWhenCookieBelongsToDifferentAccount() {
        let snapshotStore = InMemorySnapshotStore()
        snapshotStore.storedRecord = SnapshotStoreRecord(
            accountIdV2: "12345",
            snapshot: makeDailyNoteSnapshot(
                fetchedAt: Date(timeIntervalSince1970: 1_741_700_000),
                currentResin: 180,
                resinRecoveryTimeSeconds: 9_600
            ),
            trackingState: .empty
        )

        let coordinator = RefreshCoordinator(
            accountResolver: MockAccountResolver(result: .failure(.missingAccountID)),
            dailyNoteService: MockDailyNoteService(results: []),
            snapshotStore: snapshotStore,
            clock: ManualRefreshClock(now: Date())
        )

        coordinator.start(cookie: "account_id_v2=99999; cookie_token_v2=abcdef")

        #expect(coordinator.latestSnapshot == nil)
        #expect(coordinator.trackingState == .empty)
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
            snapshotStore: InMemorySnapshotStore(),
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
}
