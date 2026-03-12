import Foundation
@testable import NotEnoughResins
import Testing

struct ResinTrackerTests {
    private let tracker = ResinTracker()

    @Test
    func belowCapSnapshotUpdatesPredictedFullAtAndClearsOverflowState() {
        let fetchedAt = Date(timeIntervalSince1970: 1_741_700_000)
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: fetchedAt,
            currentResin: 120,
            resinRecoveryTimeSeconds: 38_400
        )

        let trackingState = tracker.updateTrackingState(
            with: snapshot,
            previousState: ResinTrackingState(
                lastBelowCapSnapshotAt: fetchedAt.addingTimeInterval(-600),
                predictedFullAt: fetchedAt.addingTimeInterval(30_000),
                overflowStartAt: fetchedAt.addingTimeInterval(-4_800),
                lastKnownWastedResin: 10
            )
        )

        #expect(trackingState.lastBelowCapSnapshotAt == fetchedAt)
        #expect(trackingState.predictedFullAt == fetchedAt.addingTimeInterval(38_400))
        #expect(trackingState.overflowStartAt == nil)
        #expect(trackingState.lastKnownWastedResin == nil)
    }

    @Test
    func cappedSnapshotUsesPriorPredictionAsOverflowBaseline() {
        let predictedFullAt = Date(timeIntervalSince1970: 1_741_700_000)
        let fetchedAt = predictedFullAt.addingTimeInterval(2_400)
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: fetchedAt,
            currentResin: 200,
            resinRecoveryTimeSeconds: 0
        )

        let trackingState = tracker.updateTrackingState(
            with: snapshot,
            previousState: ResinTrackingState(
                lastBelowCapSnapshotAt: predictedFullAt.addingTimeInterval(-9_600),
                predictedFullAt: predictedFullAt,
                overflowStartAt: nil,
                lastKnownWastedResin: nil
            )
        )

        #expect(trackingState.overflowStartAt == predictedFullAt)
        #expect(trackingState.lastKnownWastedResin == 5)
    }

    @Test
    func cappedSnapshotWithoutReliableBaselineDoesNotInventWaste() {
        let fetchedAt = Date(timeIntervalSince1970: 1_741_700_000)
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: fetchedAt,
            currentResin: 200,
            resinRecoveryTimeSeconds: 0
        )

        let trackingState = tracker.updateTrackingState(
            with: snapshot,
            previousState: ResinTrackingState(
                lastBelowCapSnapshotAt: fetchedAt.addingTimeInterval(-600),
                predictedFullAt: fetchedAt.addingTimeInterval(600),
                overflowStartAt: nil,
                lastKnownWastedResin: nil
            )
        )

        #expect(trackingState.overflowStartAt == nil)
        #expect(trackingState.lastKnownWastedResin == nil)
        #expect(trackingState.predictedFullAt == nil)
    }

    @Test
    func derivedStateIncreasesResinWithoutExceedingCap() {
        let fetchedAt = Date(timeIntervalSince1970: 1_741_700_000)
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: fetchedAt,
            currentResin: 198,
            resinRecoveryTimeSeconds: 1_920
        )

        let derivedState = tracker.derivedState(
            from: snapshot,
            trackingState: ResinTrackingState(
                lastBelowCapSnapshotAt: fetchedAt,
                predictedFullAt: fetchedAt.addingTimeInterval(1_920),
                overflowStartAt: nil,
                lastKnownWastedResin: nil
            ),
            now: fetchedAt.addingTimeInterval(9_600)
        )

        #expect(derivedState.currentResin == 200)
        #expect(derivedState.wastedResin == nil)
    }

    @Test
    func derivedStateContinuesKnownOverflowAcrossRelaunches() {
        let fetchedAt = Date(timeIntervalSince1970: 1_741_700_000)
        let overflowStartAt = fetchedAt.addingTimeInterval(-1_440)
        let snapshot = makeDailyNoteSnapshot(
            fetchedAt: fetchedAt,
            currentResin: 200,
            resinRecoveryTimeSeconds: 0
        )

        let derivedState = tracker.derivedState(
            from: snapshot,
            trackingState: ResinTrackingState(
                lastBelowCapSnapshotAt: fetchedAt.addingTimeInterval(-9_600),
                predictedFullAt: overflowStartAt,
                overflowStartAt: overflowStartAt,
                lastKnownWastedResin: 3
            ),
            now: fetchedAt.addingTimeInterval(960)
        )

        #expect(derivedState.currentResin == 200)
        #expect(derivedState.wastedResin == 5)
    }
}
