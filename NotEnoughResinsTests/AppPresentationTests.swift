import Foundation
@testable import NotEnoughResins
import Testing

struct AppPresentationTests {
    private let builder = AppPresentationBuilder()

    @Test
    func needsConfigurationMapsToSetupMenuState() {
        let presentation = builder.makePresentation(
            configurationState: .needsConfiguration,
            refreshPhase: .needsConfiguration,
            resolvedAccount: nil,
            latestSnapshot: nil,
            trackingState: .empty,
            derivedResinState: nil,
            lastSuccessfulFetchAt: nil,
            now: Date(timeIntervalSince1970: 1_741_800_000)
        )

        #expect(presentation.menuBarState == .needsConfiguration)
        #expect(presentation.title == "Configuration Needed")
        #expect(presentation.panel == nil)
    }

    @Test
    func readyBelowCapMapsToNormalMenuState() {
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: Date(timeIntervalSince1970: 1_741_800_000),
            currentResin: 160,
            resinRecoveryTimeSeconds: 19_200
        )

        let presentation = builder.makePresentation(
            configurationState: .configurationReady,
            refreshPhase: .ready,
            resolvedAccount: ResolvedAccount(
                accountIdV2: "12345",
                server: "os_asia",
                roleId: "987654321",
                nickname: "Traveler",
                level: 60
            ),
            latestSnapshot: snapshot,
            trackingState: ResinTrackingState(
                lastBelowCapSnapshotAt: snapshot.fetchedAt,
                predictedFullAt: snapshot.fetchedAt.addingTimeInterval(19_200),
                overflowStartAt: nil,
                lastKnownWastedResin: nil
            ),
            derivedResinState: DerivedResinState(
                currentResin: 160,
                maxResin: 200,
                wastedResin: nil
            ),
            lastSuccessfulFetchAt: snapshot.fetchedAt,
            now: snapshot.fetchedAt
        )

        #expect(presentation.menuBarState == .normal(current: 160, max: 200))
        #expect(presentation.title == "Daily Note Ready")
        #expect(presentation.message == "Current account: Traveler on os_asia")
        #expect(presentation.panel?.hero.value == "160 / 200")
        #expect(presentation.panel?.hero.detail == "Full in 05:20")
        #expect(presentation.panel?.summaryMetrics.map(\.id) == [
            "weeklyBosses",
            "dailyCommissions",
            "reward",
            "realmCurrency",
        ])
        #expect(presentation.panel?.summaryMetrics.map(\.label) == [
            "Weekly Bosses",
            "Daily Commissions",
            "Bonus Reward",
            "Realm Currency",
        ])
        #expect(presentation.panel?.summaryMetrics.map(\.value) == [
            "3 / 3",
            "0 left",
            "Claimed",
            "1200 / 2400",
        ])
        #expect(presentation.panel?.expeditionSection?.rows.count == 2)
        #expect(presentation.panel?.expeditionSection?.rows[0].avatarURL == URL(string: "https://example.com/Character_A.png"))
        #expect(presentation.panel?.expeditionSection?.rows[0].characterLabel == "Character A")
        #expect(presentation.panel?.expeditionSection?.rows[0].value == "00:18 remaining")
    }

    @Test
    func belowCapCountdownUsesPredictedFullBaseline() {
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: Date(timeIntervalSince1970: 1_741_800_000),
            currentResin: 160,
            resinRecoveryTimeSeconds: 19_200
        )

        let presentation = builder.makePresentation(
            configurationState: .configurationReady,
            refreshPhase: .ready,
            resolvedAccount: nil,
            latestSnapshot: snapshot,
            trackingState: ResinTrackingState(
                lastBelowCapSnapshotAt: snapshot.fetchedAt,
                predictedFullAt: snapshot.fetchedAt.addingTimeInterval(19_200),
                overflowStartAt: nil,
                lastKnownWastedResin: nil
            ),
            derivedResinState: DerivedResinState(
                currentResin: 160,
                maxResin: 200,
                wastedResin: nil
            ),
            lastSuccessfulFetchAt: snapshot.fetchedAt,
            now: snapshot.fetchedAt.addingTimeInterval(60)
        )

        #expect(presentation.panel?.hero.detail == "Full in 05:19")
    }

    @Test
    func belowCapCountdownIsHiddenWithoutPredictedFullBaseline() {
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: Date(timeIntervalSince1970: 1_741_800_000),
            currentResin: 160,
            resinRecoveryTimeSeconds: 19_200
        )

        let presentation = builder.makePresentation(
            configurationState: .configurationReady,
            refreshPhase: .ready,
            resolvedAccount: nil,
            latestSnapshot: snapshot,
            trackingState: .empty,
            derivedResinState: DerivedResinState(
                currentResin: 160,
                maxResin: 200,
                wastedResin: nil
            ),
            lastSuccessfulFetchAt: snapshot.fetchedAt,
            now: snapshot.fetchedAt.addingTimeInterval(60)
        )

        #expect(presentation.panel?.hero.detail == nil)
    }

    @Test
    func knownOverflowMapsToOverflowMenuState() {
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: Date(timeIntervalSince1970: 1_741_800_000),
            currentResin: 200,
            resinRecoveryTimeSeconds: 0
        )

        let presentation = builder.makePresentation(
            configurationState: .configurationReady,
            refreshPhase: .ready,
            resolvedAccount: nil,
            latestSnapshot: snapshot,
            trackingState: ResinTrackingState(
                lastBelowCapSnapshotAt: snapshot.fetchedAt.addingTimeInterval(-3_840),
                predictedFullAt: snapshot.fetchedAt.addingTimeInterval(-3_360),
                overflowStartAt: snapshot.fetchedAt.addingTimeInterval(-3_360),
                lastKnownWastedResin: 7
            ),
            derivedResinState: DerivedResinState(
                currentResin: 200,
                maxResin: 200,
                wastedResin: 7
            ),
            lastSuccessfulFetchAt: snapshot.fetchedAt,
            now: snapshot.fetchedAt
        )

        #expect(presentation.menuBarState == .overflow(wasted: 7))
        #expect(presentation.title == "Overflow Detected")
        #expect(presentation.panel?.hero.detail == nil)
        #expect(presentation.panel?.hero.accessory == .init(label: "Estimated Waste", value: "7"))
    }

    @Test
    func authErrorOverridesLastSuccessfulSnapshotState() {
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: Date(timeIntervalSince1970: 1_741_800_000),
            currentResin: 180,
            resinRecoveryTimeSeconds: 9_600
        )

        let presentation = builder.makePresentation(
            configurationState: .configurationReady,
            refreshPhase: .authError("HoYoLAB rejected the saved cookie. Please sign in again."),
            resolvedAccount: nil,
            latestSnapshot: snapshot,
            trackingState: ResinTrackingState(
                lastBelowCapSnapshotAt: snapshot.fetchedAt,
                predictedFullAt: snapshot.fetchedAt.addingTimeInterval(9_600),
                overflowStartAt: nil,
                lastKnownWastedResin: nil
            ),
            derivedResinState: DerivedResinState(
                currentResin: 181,
                maxResin: 200,
                wastedResin: nil
            ),
            lastSuccessfulFetchAt: snapshot.fetchedAt,
            now: snapshot.fetchedAt
        )

        #expect(presentation.menuBarState == .authError)
        #expect(presentation.title == "Authentication Failed")
        #expect(presentation.panel != nil)
    }

    @Test
    func requestErrorOverridesLastSuccessfulSnapshotState() {
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: Date(timeIntervalSince1970: 1_741_800_000),
            currentResin: 175,
            resinRecoveryTimeSeconds: 12_000
        )

        let presentation = builder.makePresentation(
            configurationState: .configurationReady,
            refreshPhase: .requestError(
                "The latest Daily Note request failed. Try again after checking the connection."
            ),
            resolvedAccount: nil,
            latestSnapshot: snapshot,
            trackingState: ResinTrackingState(
                lastBelowCapSnapshotAt: snapshot.fetchedAt,
                predictedFullAt: snapshot.fetchedAt.addingTimeInterval(12_000),
                overflowStartAt: nil,
                lastKnownWastedResin: nil
            ),
            derivedResinState: DerivedResinState(
                currentResin: 176,
                maxResin: 200,
                wastedResin: nil
            ),
            lastSuccessfulFetchAt: snapshot.fetchedAt,
            now: snapshot.fetchedAt
        )

        #expect(presentation.menuBarState == .requestError)
        #expect(presentation.title == "Request Failed")
        #expect(presentation.panel != nil)
    }

    @Test
    func finishedExpeditionMapsToCompletedRow() {
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: Date(timeIntervalSince1970: 1_741_800_000),
            currentResin: 150,
            resinRecoveryTimeSeconds: 24_000,
            expeditions: [
                makeDailyNoteExpedition(
                    avatarSideIcon: "https://example.com/Character_C.png",
                    status: "Finished",
                    remainedTimeSeconds: 0
                ),
            ]
        )

        let presentation = builder.makePresentation(
            configurationState: .configurationReady,
            refreshPhase: .ready,
            resolvedAccount: nil,
            latestSnapshot: snapshot,
            trackingState: ResinTrackingState(
                lastBelowCapSnapshotAt: snapshot.fetchedAt,
                predictedFullAt: snapshot.fetchedAt.addingTimeInterval(24_000),
                overflowStartAt: nil,
                lastKnownWastedResin: nil
            ),
            derivedResinState: DerivedResinState(
                currentResin: 150,
                maxResin: 200,
                wastedResin: nil
            ),
            lastSuccessfulFetchAt: snapshot.fetchedAt,
            now: snapshot.fetchedAt
        )

        #expect(presentation.panel?.expeditionSection?.rows[0].avatarURL == URL(string: "https://example.com/Character_C.png"))
        #expect(presentation.panel?.expeditionSection?.rows[0].characterLabel == "Character C")
        #expect(presentation.panel?.expeditionSection?.rows[0].value == "Completed")
    }
}
