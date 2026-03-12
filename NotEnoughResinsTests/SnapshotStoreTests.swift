import Foundation
import Testing
@testable import NotEnoughResins

struct SnapshotStoreTests {
    @Test
    func savesAndRestoresSnapshotTrackingRecord() throws {
        let suiteName = "NotEnoughResinsTests.SnapshotStore.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create isolated UserDefaults suite.")
            return
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let store = SnapshotStore(userDefaults: userDefaults)
        let fetchedAt = Date(timeIntervalSince1970: 1_741_700_000)
        let record = SnapshotStoreRecord(
            accountIdV2: "12345",
            snapshot: makeDailyNoteSnapshot(
                fetchedAt: fetchedAt,
                currentResin: 176,
                resinRecoveryTimeSeconds: 11_520
            ),
            trackingState: ResinTrackingState(
                lastBelowCapSnapshotAt: fetchedAt,
                predictedFullAt: fetchedAt.addingTimeInterval(11_520),
                overflowStartAt: nil,
                lastKnownWastedResin: nil
            )
        )

        try store.save(record)
        let restoredRecord = try store.load()

        #expect(restoredRecord == record)
    }

    @Test
    func returnsDecodeFailureForCorruptData() {
        let suiteName = "NotEnoughResinsTests.SnapshotStore.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create isolated UserDefaults suite.")
            return
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        userDefaults.set(Data("not-json".utf8), forKey: SnapshotStore.storageKey)

        let store = SnapshotStore(userDefaults: userDefaults)

        do {
            _ = try store.load()
            Issue.record("Expected corrupt snapshot data to fail decoding.")
        } catch let error as SnapshotStore.StoreError {
            #expect(error == .decodeFailed)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
