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

@MainActor
final class ManualRefreshClock: RefreshClock {
    var now: Date
    private(set) var sleepCalls: [TimeInterval] = []
    private var continuations: [CheckedContinuation<Void, Error>] = []

    init(now: Date) {
        self.now = now
    }

    func sleep(seconds: TimeInterval) async throws {
        sleepCalls.append(seconds)
        try await withCheckedThrowingContinuation { continuation in
            continuations.append(continuation)
        }
    }

    func waitForSleepCall(count: Int) async {
        while sleepCalls.count < count {
            await Task.yield()
        }
    }

    func advance(by seconds: TimeInterval) {
        now = now.addingTimeInterval(seconds)
        guard continuations.isEmpty == false else {
            return
        }

        let continuation = continuations.removeFirst()
        continuation.resume()
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
    private var queuedResults: [Result<DailyNoteSnapshot, DailyNoteServiceError>]
    private(set) var requests: [(cookie: String, account: ResolvedAccount, fetchedAt: Date)] = []

    init(results: [Result<DailyNoteSnapshot, DailyNoteServiceError>]) {
        queuedResults = results
    }

    func fetchDailyNote(
        cookie: String,
        account: ResolvedAccount,
        at fetchedAt: Date
    ) async throws -> DailyNoteSnapshot {
        requests.append((cookie: cookie, account: account, fetchedAt: fetchedAt))
        return try queuedResults.removeFirst().get()
    }
}

func makeHTTPURLResponse(for url: URL, statusCode: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}
