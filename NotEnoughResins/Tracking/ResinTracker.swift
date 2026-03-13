import Foundation

struct ResinTrackingState: Codable, Equatable {
    var lastBelowCapSnapshotAt: Date?
    var predictedFullAt: Date?
    var overflowStartAt: Date?
    var lastKnownWastedResin: Int?

    static let empty = ResinTrackingState(
        lastBelowCapSnapshotAt: nil,
        predictedFullAt: nil,
        overflowStartAt: nil,
        lastKnownWastedResin: nil
    )
}

struct DerivedResinState: Equatable {
    let currentResin: Int
    let maxResin: Int
    let wastedResin: Int?
}

struct ResinTracker {
    nonisolated static let recoveryIntervalSeconds = 480

    nonisolated func updateTrackingState(
        with snapshot: DailyNoteSnapshot,
        previousState: ResinTrackingState
    ) -> ResinTrackingState {
        guard snapshot.currentResin >= snapshot.maxResin else {
            return ResinTrackingState(
                lastBelowCapSnapshotAt: snapshot.fetchedAt,
                predictedFullAt: snapshot.fetchedAt.addingTimeInterval(
                    TimeInterval(snapshot.resinRecoveryTimeSeconds)
                ),
                overflowStartAt: nil,
                lastKnownWastedResin: nil
            )
        }

        let overflowStartAt = previousState.overflowStartAt
            ?? validatedOverflowStartAt(
                predictedFullAt: previousState.predictedFullAt,
                fetchedAt: snapshot.fetchedAt
            )

        let wastedResin = overflowStartAt.map { overflowStartAt in
            derivedWastedResin(
                now: snapshot.fetchedAt,
                overflowStartAt: overflowStartAt,
                fallback: previousState.lastKnownWastedResin
            )
        }

        return ResinTrackingState(
            lastBelowCapSnapshotAt: previousState.lastBelowCapSnapshotAt,
            predictedFullAt: overflowStartAt == nil ? nil : previousState.predictedFullAt,
            overflowStartAt: overflowStartAt,
            lastKnownWastedResin: wastedResin
        )
    }

    nonisolated func derivedState(
        from snapshot: DailyNoteSnapshot,
        trackingState: ResinTrackingState,
        now: Date
    ) -> DerivedResinState {
        let derivedCurrentResin = min(
            snapshot.maxResin,
            snapshot.currentResin + recoveredResin(since: snapshot.fetchedAt, now: now)
        )

        guard let overflowStartAt = trackingState.overflowStartAt else {
            return DerivedResinState(
                currentResin: derivedCurrentResin,
                maxResin: snapshot.maxResin,
                wastedResin: nil
            )
        }

        return DerivedResinState(
            currentResin: snapshot.maxResin,
            maxResin: snapshot.maxResin,
            wastedResin: derivedWastedResin(
                now: now,
                overflowStartAt: overflowStartAt,
                fallback: trackingState.lastKnownWastedResin
            )
        )
    }

    private nonisolated func recoveredResin(since fetchedAt: Date, now: Date) -> Int {
        let elapsedSeconds = max(0, Int(now.timeIntervalSince(fetchedAt)))
        return elapsedSeconds / Self.recoveryIntervalSeconds
    }

    private nonisolated func validatedOverflowStartAt(
        predictedFullAt: Date?,
        fetchedAt: Date
    ) -> Date? {
        guard let predictedFullAt, predictedFullAt <= fetchedAt else {
            return nil
        }

        return predictedFullAt
    }

    private nonisolated func derivedWastedResin(
        now: Date,
        overflowStartAt: Date,
        fallback: Int?
    ) -> Int {
        let elapsedSeconds = max(0, Int(now.timeIntervalSince(overflowStartAt)))
        let wastedResin = elapsedSeconds / Self.recoveryIntervalSeconds
        return max(fallback ?? 0, wastedResin)
    }
}
