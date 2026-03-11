import Foundation

protocol DailyNoteFetching {
    func fetchDailyNote(cookie: String, account: ResolvedAccount, at fetchedAt: Date) async throws -> DailyNoteSnapshot
}

enum DailyNoteServiceError: Error, Equatable, LocalizedError {
    case authFailure
    case requestFailure(String)
    case invalidResponse
    case transportFailure(String)

    var errorDescription: String? {
        switch self {
        case .authFailure:
            "HoYoLAB rejected the saved cookie. Please sign in again."
        case .requestFailure(let message):
            message
        case .invalidResponse:
            "HoYoLAB returned a Daily Note response that the app could not decode."
        case .transportFailure(let message):
            message
        }
    }
}

struct DailyNoteService: DailyNoteFetching {
    private let httpClient: HTTPDataLoading
    private let decoder: JSONDecoder

    init(httpClient: HTTPDataLoading, decoder: JSONDecoder = JSONDecoder()) {
        self.httpClient = httpClient
        self.decoder = decoder
    }

    func fetchDailyNote(
        cookie: String,
        account: ResolvedAccount,
        at fetchedAt: Date
    ) async throws -> DailyNoteSnapshot {
        let request = try makeRequest(
            url: HoYoLabEndpoint.dailyNote,
            queryItems: [
                URLQueryItem(name: "server", value: account.server),
                URLQueryItem(name: "role_id", value: account.roleId),
            ],
            cookie: cookie
        )

        let data = try await loadData(for: request)

        do {
            let envelope = try decoder.decode(HoYoLabEnvelope<DailyNotePayload>.self, from: data)

            switch envelope.retcode {
            case 0:
                guard let payload = envelope.data,
                      let resinRecoveryTimeSeconds = Int(payload.resinRecoveryTime),
                      let homeCoinRecoveryTimeSeconds = Int(payload.homeCoinRecoveryTime) else {
                    throw DailyNoteServiceError.invalidResponse
                }

                return DailyNoteSnapshot(
                    fetchedAt: fetchedAt,
                    currentResin: payload.currentResin,
                    maxResin: payload.maxResin,
                    resinRecoveryTimeSeconds: resinRecoveryTimeSeconds,
                    currentHomeCoin: payload.currentHomeCoin,
                    maxHomeCoin: payload.maxHomeCoin,
                    homeCoinRecoveryTimeSeconds: homeCoinRecoveryTimeSeconds,
                    finishedTaskCount: payload.finishedTaskNum,
                    totalTaskCount: payload.totalTaskNum,
                    extraTaskRewardReceived: payload.isExtraTaskRewardReceived,
                    remainingResinDiscounts: payload.remainResinDiscountNum,
                    resinDiscountLimit: payload.resinDiscountNumLimit,
                    currentExpeditionCount: payload.currentExpeditionNum,
                    maxExpeditionCount: payload.maxExpeditionNum
                )
            case 10001 where envelope.message == "Please login":
                throw DailyNoteServiceError.authFailure
            default:
                throw DailyNoteServiceError.requestFailure(envelope.message)
            }
        } catch let error as DailyNoteServiceError {
            throw error
        } catch {
            throw DailyNoteServiceError.invalidResponse
        }
    }

    private func makeRequest(url: URL, queryItems: [URLQueryItem], cookie: String) throws -> URLRequest {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw DailyNoteServiceError.invalidResponse
        }

        components.queryItems = queryItems

        guard let resolvedURL = components.url else {
            throw DailyNoteServiceError.invalidResponse
        }

        var request = URLRequest(url: resolvedURL)
        request.httpMethod = "GET"
        request.setValue(cookie, forHTTPHeaderField: "Cookie")
        return request
    }

    private func loadData(for request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await httpClient.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw DailyNoteServiceError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw DailyNoteServiceError.requestFailure("HTTP \(httpResponse.statusCode)")
            }

            return data
        } catch let error as DailyNoteServiceError {
            throw error
        } catch {
            throw DailyNoteServiceError.transportFailure(error.localizedDescription)
        }
    }
}
