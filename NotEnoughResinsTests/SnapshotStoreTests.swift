import Foundation
@testable import NotEnoughResins
import Testing

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

    @Test
    func restoresLegacySnapshotRecordWithoutExpeditionArray() throws {
        let suiteName = "NotEnoughResinsTests.SnapshotStore.Legacy.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create isolated UserDefaults suite.")
            return
        }

        defer {
            userDefaults.removePersistentDomain(forName: suiteName)
        }

        let legacyPayload = """
        {
          "schemaVersion": 1,
          "accountIdV2": "12345",
          "snapshot": {
            "fetchedAt": 1741700000,
            "currentResin": 176,
            "maxResin": 200,
            "resinRecoveryTimeSeconds": 11520,
            "currentHomeCoin": 1200,
            "maxHomeCoin": 2400,
            "homeCoinRecoveryTimeSeconds": 3600,
            "finishedTaskCount": 4,
            "totalTaskCount": 4,
            "extraTaskRewardReceived": true,
            "remainingResinDiscounts": 3,
            "resinDiscountLimit": 3,
            "currentExpeditionCount": 2,
            "maxExpeditionCount": 5
          },
          "trackingState": {
            "lastBelowCapSnapshotAt": 1741700000,
            "predictedFullAt": 1741711520,
            "overflowStartAt": null,
            "lastKnownWastedResin": null
          }
        }
        """

        userDefaults.set(Data(legacyPayload.utf8), forKey: SnapshotStore.storageKey)

        let store = SnapshotStore(userDefaults: userDefaults)
        let restoredRecord = try store.load()

        #expect(restoredRecord?.snapshot.expeditions == [])
    }
}
