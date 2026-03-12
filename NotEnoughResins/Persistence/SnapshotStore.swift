import Foundation

protocol SnapshotStoring {
    func load() throws -> SnapshotStoreRecord?
    func save(_ record: SnapshotStoreRecord) throws
    func clear() throws
}

struct SnapshotStoreRecord: Equatable {
    let accountIdV2: String
    let snapshot: DailyNoteSnapshot
    let trackingState: ResinTrackingState
}

struct SnapshotStore: SnapshotStoring {
    enum StoreError: Error, Equatable, LocalizedError {
        case decodeFailed
        case encodeFailed

        var errorDescription: String? {
            switch self {
            case .decodeFailed:
                "The cached Daily Note snapshot could not be restored."
            case .encodeFailed:
                "The latest Daily Note snapshot could not be saved."
            }
        }
    }

    static let storageKey = "snapshot-store.v1"

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        userDefaults: UserDefaults,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
    }

    static func live() -> SnapshotStore {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "NotEnoughResins"
        let suiteSuffix = ProcessInfo.processInfo.environment["NOT_ENOUGH_RESINS_USER_DEFAULTS_SUFFIX"]
        let suiteName = [bundleIdentifier, suiteSuffix]
            .compactMap { $0 }
            .joined(separator: ".")

        let userDefaults = suiteSuffix == nil
            ? UserDefaults.standard
            : (UserDefaults(suiteName: suiteName) ?? .standard)

        return SnapshotStore(userDefaults: userDefaults)
    }

    func load() throws -> SnapshotStoreRecord? {
        guard let data = userDefaults.data(forKey: Self.storageKey) else {
            return nil
        }

        do {
            let persistedRecord = try decoder.decode(PersistedSnapshotStoreRecord.self, from: data)
            guard persistedRecord.schemaVersion == 1 else {
                throw StoreError.decodeFailed
            }
            return persistedRecord.record
        } catch {
            throw StoreError.decodeFailed
        }
    }

    func save(_ record: SnapshotStoreRecord) throws {
        do {
            let data = try encoder.encode(PersistedSnapshotStoreRecord(record: record))
            userDefaults.set(data, forKey: Self.storageKey)
        } catch {
            throw StoreError.encodeFailed
        }
    }

    func clear() throws {
        userDefaults.removeObject(forKey: Self.storageKey)
    }
}

private struct PersistedSnapshotStoreRecord: Codable {
    let schemaVersion: Int
    let accountIdV2: String
    let snapshot: DailyNoteSnapshot
    let trackingState: ResinTrackingState

    init(record: SnapshotStoreRecord) {
        schemaVersion = 1
        accountIdV2 = record.accountIdV2
        snapshot = record.snapshot
        trackingState = record.trackingState
    }

    var record: SnapshotStoreRecord {
        SnapshotStoreRecord(
            accountIdV2: accountIdV2,
            snapshot: snapshot,
            trackingState: trackingState
        )
    }
}
