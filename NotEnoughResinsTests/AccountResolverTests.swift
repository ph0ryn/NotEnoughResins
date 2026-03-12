import Foundation
@testable import NotEnoughResins
import Testing

struct AccountResolverTests {
    @Test
    func resolvesGenshinAccountFromCookieAndCardResponse() async throws {
        let httpClient = MockHTTPClient { request in
            #expect(request.value(forHTTPHeaderField: "Cookie") == "account_id_v2=12345; cookie_token_v2=abcdef")
            #expect(request.url?.host == "sg-public-api.hoyolab.com")
            #expect(request.url?.path == "/event/game_record/card/wapi/getGameRecordCard")
            #expect(URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first?.value == "12345")

            let body = """
            {
              "retcode": 0,
              "message": "OK",
              "data": {
                "list": [
                  {
                    "game_id": 1,
                    "region": "ignored",
                    "region_name": "Ignored",
                    "game_role_id": "111",
                    "nickname": "Ignored",
                    "level": 1,
                    "has_role": true
                  },
                  {
                    "game_id": 2,
                    "region": "os_asia",
                    "region_name": "Asia Server",
                    "game_role_id": "987654321",
                    "nickname": "Traveler",
                    "level": 60,
                    "has_role": true
                  }
                ]
              }
            }
            """

            return (
                Data(body.utf8),
                makeHTTPURLResponse(for: request.url!)
            )
        }

        let resolver = AccountResolver(httpClient: httpClient)
        let resolvedAccount = try await resolver.resolveAccount(
            from: "account_id_v2=12345; cookie_token_v2=abcdef"
        )

        #expect(resolvedAccount.accountIdV2 == "12345")
        #expect(resolvedAccount.server == "os_asia")
        #expect(resolvedAccount.roleId == "987654321")
        #expect(resolvedAccount.nickname == "Traveler")
        #expect(resolvedAccount.level == 60)
    }

    @Test
    func rejectsCookieWithoutAccountID() async {
        let resolver = AccountResolver(httpClient: MockHTTPClient { _ in
            Issue.record("Unexpected request: \\(String(describing: request.url))")
            return (Data(), makeHTTPURLResponse(for: URL(string: "https://example.com")!))
        })

        do {
            _ = try await resolver.resolveAccount(from: "cookie_token_v2=abcdef")
            Issue.record("Expected the resolver to reject a cookie without account_id_v2.")
        } catch let error as AccountResolverError {
            #expect(error == .missingAccountID)
        } catch {
            Issue.record("Unexpected error: \\(error)")
        }
    }

    @Test
    func mapsAuthFailureSeparatelyFromGenericRequestFailure() async {
        let authClient = MockHTTPClient { request in
            let body = """
            {"retcode":10001,"message":"Please login","data":null}
            """
            return (Data(body.utf8), makeHTTPURLResponse(for: request.url!))
        }
        let requestClient = MockHTTPClient { request in
            let body = """
            {"retcode":-1,"message":"Invalid uid","data":null}
            """
            return (Data(body.utf8), makeHTTPURLResponse(for: request.url!))
        }

        let authResolver = AccountResolver(httpClient: authClient)
        let requestResolver = AccountResolver(httpClient: requestClient)

        do {
            _ = try await authResolver.resolveAccount(from: "account_id_v2=12345")
            Issue.record("Expected auth failure.")
        } catch let error as AccountResolverError {
            #expect(error == .authFailure)
        } catch {
            Issue.record("Unexpected error: \\(error)")
        }

        do {
            _ = try await requestResolver.resolveAccount(from: "account_id_v2=12345")
            Issue.record("Expected request failure.")
        } catch let error as AccountResolverError {
            #expect(error == .requestFailure("Invalid uid"))
        } catch {
            Issue.record("Unexpected error: \\(error)")
        }
    }
}
