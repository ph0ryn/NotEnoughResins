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

    nonisolated init() {}

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
        #if DEBUG
            // Development builds pin overflow start to a fixed time yesterday so the
            // overflow UI remains visible during local iteration without mutating
            // live account data.
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = .current
                let yesterday = calendar.date(byAdding: .day, value: -1, to: fetchedAt)
                    ?? fetchedAt.addingTimeInterval(-86_400)
                let yesterdayComponents = calendar.dateComponents([.year, .month, .day], from: yesterday)

                return calendar.date(
                    from: DateComponents(
                        year: yesterdayComponents.year,
                        month: yesterdayComponents.month,
                        day: yesterdayComponents.day,
                        hour: 15,
                        minute: 0,
                        second: 0
                    )
                ) ?? yesterday
            }
        #endif

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
