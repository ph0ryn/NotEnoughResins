import Foundation

enum HoYoLabEndpoint {
    static let gameRecordCard = URL(string: "https://sg-public-api.hoyolab.com/event/game_record/card/wapi/getGameRecordCard")!
    static let dailyNote = URL(string: "https://sg-public-api.hoyolab.com/event/game_record/app/genshin/api/dailyNote")!
}

struct HoYoLabEnvelope<T: Decodable>: Decodable {
    let retcode: Int
    let message: String
    let data: T?
}

struct GameRecordCardData: Decodable {
    let list: [GameRecordCardEntry]
}

struct GameRecordCardEntry: Decodable, Equatable {
    let gameID: Int
    let region: String
    let regionName: String
    let gameRoleID: String
    let nickname: String?
    let level: Int?
    let hasRole: Bool

    enum CodingKeys: String, CodingKey {
        case gameID = "game_id"
        case region
        case regionName = "region_name"
        case gameRoleID = "game_role_id"
        case nickname
        case level
        case hasRole = "has_role"
    }
}

struct ResolvedAccount: Equatable {
    let accountIdV2: String
    let server: String
    let roleId: String
    let nickname: String?
    let level: Int?
}

struct DailyNotePayload: Decodable, Equatable {
    let currentResin: Int
    let maxResin: Int
    let resinRecoveryTime: String
    let currentHomeCoin: Int
    let maxHomeCoin: Int
    let homeCoinRecoveryTime: String
    let finishedTaskNum: Int
    let totalTaskNum: Int
    let isExtraTaskRewardReceived: Bool
    let remainResinDiscountNum: Int
    let resinDiscountNumLimit: Int
    let currentExpeditionNum: Int
    let maxExpeditionNum: Int

    enum CodingKeys: String, CodingKey {
        case currentResin = "current_resin"
        case maxResin = "max_resin"
        case resinRecoveryTime = "resin_recovery_time"
        case currentHomeCoin = "current_home_coin"
        case maxHomeCoin = "max_home_coin"
        case homeCoinRecoveryTime = "home_coin_recovery_time"
        case finishedTaskNum = "finished_task_num"
        case totalTaskNum = "total_task_num"
        case isExtraTaskRewardReceived = "is_extra_task_reward_received"
        case remainResinDiscountNum = "remain_resin_discount_num"
        case resinDiscountNumLimit = "resin_discount_num_limit"
        case currentExpeditionNum = "current_expedition_num"
        case maxExpeditionNum = "max_expedition_num"
    }
}

struct DailyNoteSnapshot: Codable, Equatable {
    let fetchedAt: Date
    let currentResin: Int
    let maxResin: Int
    let resinRecoveryTimeSeconds: Int
    let currentHomeCoin: Int
    let maxHomeCoin: Int
    let homeCoinRecoveryTimeSeconds: Int
    let finishedTaskCount: Int
    let totalTaskCount: Int
    let extraTaskRewardReceived: Bool
    let remainingResinDiscounts: Int
    let resinDiscountLimit: Int
    let currentExpeditionCount: Int
    let maxExpeditionCount: Int
}
