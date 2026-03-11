import Foundation
import Testing
@testable import NotEnoughResins

@MainActor
struct RefreshCoordinatorTests {
    @Test
    func startupDiscoveryRunsOnceBeforeInitialAndScheduledRefreshes() async throws {
        let clock = ManualRefreshClock(now: Date(timeIntervalSince1970: 1_741_600_000))
        let account = ResolvedAccount(
            accountIdV2: "12345",
            server: "os_asia",
            roleId: "987654321",
            nickname: "Traveler",
            level: 60
        )
        let snapshots = [
            DailyNoteSnapshot(
                fetchedAt: clock.now,
                currentResin: 150,
                maxResin: 200,
                resinRecoveryTimeSeconds: 24_000,
                currentHomeCoin: 1_200,
                maxHomeCoin: 2_400,
                homeCoinRecoveryTimeSeconds: 3_600,
                finishedTaskCount: 4,
                totalTaskCount: 4,
                extraTaskRewardReceived: true,
                remainingResinDiscounts: 3,
                resinDiscountLimit: 3,
                currentExpeditionCount: 2,
                maxExpeditionCount: 5
            ),
            DailyNoteSnapshot(
                fetchedAt: clock.now.addingTimeInterval(600),
                currentResin: 151,
                maxResin: 200,
                resinRecoveryTimeSeconds: 23_400,
                currentHomeCoin: 1_250,
                maxHomeCoin: 2_400,
                homeCoinRecoveryTimeSeconds: 3_000,
                finishedTaskCount: 4,
                totalTaskCount: 4,
                extraTaskRewardReceived: true,
                remainingResinDiscounts: 3,
                resinDiscountLimit: 3,
                currentExpeditionCount: 2,
                maxExpeditionCount: 5
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
}
