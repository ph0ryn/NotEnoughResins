import Foundation
@testable import NotEnoughResins
import Testing

struct DailyNoteServiceTests {
    private let account = ResolvedAccount(
        accountIdV2: "12345",
        server: "os_asia",
        roleId: "987654321",
        nickname: "Traveler",
        level: 60
    )

    @Test
    func decodesDailyNoteSnapshotAndBuildsExpectedRequest() async throws {
        let fetchedAt = Date(timeIntervalSince1970: 1_741_600_000)
        let httpClient = MockHTTPClient { request in
            #expect(request.value(forHTTPHeaderField: "Cookie") == "account_id_v2=12345; cookie_token_v2=abcdef")
            #expect(request.url?.path == "/event/game_record/app/genshin/api/dailyNote")

            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            let queryItems = Dictionary(uniqueKeysWithValues: (components?.queryItems ?? []).map { ($0.name, $0.value ?? "") })
            #expect(queryItems["server"] == "os_asia")
            #expect(queryItems["role_id"] == "987654321")

            let body = """
            {
              "retcode": 0,
              "message": "OK",
              "data": {
                "current_resin": 160,
                "max_resin": 200,
                "resin_recovery_time": "19200",
                "current_home_coin": 1200,
                "max_home_coin": 2400,
                "home_coin_recovery_time": "3600",
                "finished_task_num": 4,
                "total_task_num": 4,
                "is_extra_task_reward_received": true,
                "remain_resin_discount_num": 3,
                "resin_discount_num_limit": 3,
                "current_expedition_num": 2,
                "max_expedition_num": 5
              }
            }
            """

            return (Data(body.utf8), makeHTTPURLResponse(for: request.url!))
        }

        let service = DailyNoteService(httpClient: httpClient)
        let snapshot = try await service.fetchDailyNote(
            cookie: "account_id_v2=12345; cookie_token_v2=abcdef",
            account: account,
            at: fetchedAt
        )

        #expect(snapshot.fetchedAt == fetchedAt)
        #expect(snapshot.currentResin == 160)
        #expect(snapshot.maxResin == 200)
        #expect(snapshot.resinRecoveryTimeSeconds == 19_200)
        #expect(snapshot.currentHomeCoin == 1_200)
        #expect(snapshot.homeCoinRecoveryTimeSeconds == 3_600)
        #expect(snapshot.finishedTaskCount == 4)
        #expect(snapshot.currentExpeditionCount == 2)
    }

    @Test
    func classifiesAuthFailureAndGenericRequestFailure() async {
        let authClient = MockHTTPClient { request in
            let body = """
            {"retcode":10001,"message":"Please login","data":null}
            """
            return (Data(body.utf8), makeHTTPURLResponse(for: request.url!))
        }
        let requestClient = MockHTTPClient { request in
            let body = """
            {"retcode":-1,"message":"param role_id error: value must be greater than 0","data":null}
            """
            return (Data(body.utf8), makeHTTPURLResponse(for: request.url!))
        }

        let authService = DailyNoteService(httpClient: authClient)
        let requestService = DailyNoteService(httpClient: requestClient)

        do {
            _ = try await authService.fetchDailyNote(cookie: "cookie", account: account, at: Date())
            Issue.record("Expected auth failure.")
        } catch let error as DailyNoteServiceError {
            #expect(error == .authFailure)
        } catch {
            Issue.record("Unexpected error: \\(error)")
        }

        do {
            _ = try await requestService.fetchDailyNote(cookie: "cookie", account: account, at: Date())
            Issue.record("Expected request failure.")
        } catch let error as DailyNoteServiceError {
            #expect(error == .requestFailure("param role_id error: value must be greater than 0"))
        } catch {
            Issue.record("Unexpected error: \\(error)")
        }
    }
}
