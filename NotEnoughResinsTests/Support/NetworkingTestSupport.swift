import Foundation
@testable import NotEnoughResins

final class MockHTTPClient: HTTPDataLoading {
    typealias Handler = (URLRequest) throws -> (Data, URLResponse)

    private let handler: Handler
    private(set) var requests: [URLRequest] = []

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        return try handler(request)
    }
}

final class InMemorySnapshotStore: SnapshotStoring {
    var storedRecord: SnapshotStoreRecord?
    var loadError: Error?
    var saveError: Error?
    private(set) var savedRecords: [SnapshotStoreRecord] = []

    func load() throws -> SnapshotStoreRecord? {
        if let loadError {
            throw loadError
        }

        return storedRecord
    }

    func save(_ record: SnapshotStoreRecord) throws {
        if let saveError {
            throw saveError
        }

        storedRecord = record
        savedRecords.append(record)
    }

    func clear() throws {
        storedRecord = nil
    }
}

@MainActor
final class ManualRefreshClock: RefreshClock {
    private struct PendingSleep {
        let id: UUID
        let continuation: CheckedContinuation<Void, Error>
    }

    var now: Date
    private(set) var sleepCalls: [TimeInterval] = []
    private var pendingSleeps: [PendingSleep] = []

    init(now: Date) {
        self.now = now
    }

    func sleep(seconds: TimeInterval) async throws {
        sleepCalls.append(seconds)
        let sleepID = UUID()

        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                pendingSleeps.append(
                    PendingSleep(id: sleepID, continuation: continuation)
                )
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.cancelSleep(id: sleepID)
            }
        }
    }

    func waitForSleepCall(count: Int) async {
        while sleepCalls.count < count {
            await Task.yield()
        }
    }

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
        guard pendingSleeps.isEmpty == false else {
            return
        }

        let pendingSleep = pendingSleeps.removeFirst()
        pendingSleep.continuation.resume()
    }

    private func cancelSleep(id: UUID) {
        guard let index = pendingSleeps.firstIndex(where: { $0.id == id }) else {
            return
        }

        let pendingSleep = pendingSleeps.remove(at: index)
        pendingSleep.continuation.resume(throwing: CancellationError())
    }
}

@MainActor
final class MockAccountResolver: AccountResolving {
    private let result: Result<ResolvedAccount, AccountResolverError>
    private(set) var cookies: [String] = []

    init(result: Result<ResolvedAccount, AccountResolverError>) {
        self.result = result
    }

    func resolveAccount(from cookie: String) async throws -> ResolvedAccount {
        cookies.append(cookie)
        return try result.get()
    }
}

@MainActor
final class MockDailyNoteService: DailyNoteFetching {
    struct Request: Equatable {
        let cookie: String
        let account: ResolvedAccount
        let fetchedAt: Date
    }

    private var queuedResults: [Result<DailyNoteSnapshot, DailyNoteServiceError>]
    private(set) var requests: [Request] = []

    init(results: [Result<DailyNoteSnapshot, DailyNoteServiceError>]) {
        queuedResults = results
    }

    func fetchDailyNote(
        cookie: String,
        account: ResolvedAccount,
        at fetchedAt: Date
    ) async throws -> DailyNoteSnapshot {
        requests.append(Request(cookie: cookie, account: account, fetchedAt: fetchedAt))
        return try queuedResults.removeFirst().get()
    }
}

func makeHTTPURLResponse(for url: URL, statusCode: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

func makeDailyNoteSnapshot(
    fetchedAt: Date,
    currentResin: Int,
    maxResin: Int = 200,
    resinRecoveryTimeSeconds: Int,
    currentHomeCoin: Int = 1_200,
    maxHomeCoin: Int = 2_400,
    homeCoinRecoveryTimeSeconds: Int = 3_600,
    finishedTaskCount: Int = 4,
    totalTaskCount: Int = 4,
    extraTaskRewardReceived: Bool = true,
    remainingResinDiscounts: Int = 3,
    resinDiscountLimit: Int = 3,
    currentExpeditionCount: Int? = nil,
    maxExpeditionCount: Int = 5,
    expeditions: [DailyNoteExpedition] = makeDailyNoteExpeditions()
) -> DailyNoteSnapshot {
    DailyNoteSnapshot(
        fetchedAt: fetchedAt,
        currentResin: currentResin,
        maxResin: maxResin,
        resinRecoveryTimeSeconds: resinRecoveryTimeSeconds,
        currentHomeCoin: currentHomeCoin,
        maxHomeCoin: maxHomeCoin,
        homeCoinRecoveryTimeSeconds: homeCoinRecoveryTimeSeconds,
        finishedTaskCount: finishedTaskCount,
        totalTaskCount: totalTaskCount,
        extraTaskRewardReceived: extraTaskRewardReceived,
        remainingResinDiscounts: remainingResinDiscounts,
        resinDiscountLimit: resinDiscountLimit,
        currentExpeditionCount: currentExpeditionCount ?? expeditions.count,
        maxExpeditionCount: maxExpeditionCount,
        expeditions: expeditions
    )
}

func makeDailyNoteExpeditions() -> [DailyNoteExpedition] {
    [
        makeDailyNoteExpedition(
            avatarSideIcon: "https://example.com/Character_A.png",
            remainedTimeSeconds: 1_080
        ),
        makeDailyNoteExpedition(
            avatarSideIcon: "https://example.com/Character_B.png",
            remainedTimeSeconds: 6_120
        ),
    ]
}

func makeDailyNoteExpedition(
    avatarSideIcon: String,
    status: String = "Ongoing",
    remainedTimeSeconds: Int
) -> DailyNoteExpedition {
    DailyNoteExpedition(
        avatarSideIcon: avatarSideIcon,
        status: status,
        remainedTimeSeconds: remainedTimeSeconds
    )
}
