import Foundation

protocol AccountResolving {
    func resolveAccount(from cookie: String) async throws -> ResolvedAccount
}

enum AccountResolverError: Error, Equatable, LocalizedError {
    case missingAccountID
    case authFailure
    case requestFailure(String)
    case invalidResponse
    case genshinAccountNotFound
    case transportFailure(String)

    var errorDescription: String? {
        switch self {
        case .missingAccountID:
            "The saved cookie does not include account_id_v2."
        case .authFailure:
            "HoYoLAB rejected the saved cookie. Please sign in again."
        case .requestFailure(let message):
            message
        case .invalidResponse:
            "HoYoLAB returned a response that the app could not decode."
        case .genshinAccountNotFound:
            "No Genshin account was found for the saved HoYoLAB cookie."
        case .transportFailure(let message):
            message
        }
    }
}

enum CookieParser {
    static func accountIDV2(from cookie: String) -> String? {
        cookie
            .split(separator: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap { component -> String? in
                let pair = component.split(separator: "=", maxSplits: 1).map(String.init)
                guard pair.count == 2, pair[0] == "account_id_v2" else {
                    return nil
                }

                return pair[1]
            }
            .first
    }
}

struct AccountResolver: AccountResolving {
    private let httpClient: HTTPDataLoading
    private let decoder: JSONDecoder

    init(httpClient: HTTPDataLoading, decoder: JSONDecoder = JSONDecoder()) {
        self.httpClient = httpClient
        self.decoder = decoder
    }

    func resolveAccount(from cookie: String) async throws -> ResolvedAccount {
        guard let accountId = CookieParser.accountIDV2(from: cookie) else {
            throw AccountResolverError.missingAccountID
        }

        let request = try makeRequest(
            url: HoYoLabEndpoint.gameRecordCard,
            queryItems: [URLQueryItem(name: "uid", value: accountId)],
            cookie: cookie
        )

        let data = try await loadData(for: request)

        do {
            let envelope = try decoder.decode(HoYoLabEnvelope<GameRecordCardData>.self, from: data)

            switch envelope.retcode {
            case 0:
                guard let entry = envelope.data?.list.first(where: { $0.gameID == 2 }) else {
                    throw AccountResolverError.genshinAccountNotFound
                }

                return ResolvedAccount(
                    accountIdV2: accountId,
                    server: entry.region,
                    roleId: entry.gameRoleID,
                    nickname: entry.nickname,
                    level: entry.level
                )
            case 10001 where envelope.message == "Please login":
                throw AccountResolverError.authFailure
            default:
                throw AccountResolverError.requestFailure(envelope.message)
            }
        } catch let error as AccountResolverError {
            throw error
        } catch {
            throw AccountResolverError.invalidResponse
        }
    }

    private func makeRequest(url: URL, queryItems: [URLQueryItem], cookie: String) throws -> URLRequest {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw AccountResolverError.invalidResponse
        }

        components.queryItems = queryItems

        guard let resolvedURL = components.url else {
            throw AccountResolverError.invalidResponse
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
                throw AccountResolverError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw AccountResolverError.requestFailure("HTTP \(httpResponse.statusCode)")
            }

            return data
        } catch let error as AccountResolverError {
            throw error
        } catch {
            throw AccountResolverError.transportFailure(error.localizedDescription)
        }
    }
}
