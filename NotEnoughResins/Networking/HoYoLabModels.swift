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
    let expeditions: [DailyNoteExpeditionPayload]?

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
        case expeditions
    }
}

struct DailyNoteExpeditionPayload: Decodable, Equatable {
    let avatarSideIcon: String
    let status: String
    let remainedTime: String

    enum CodingKeys: String, CodingKey {
        case avatarSideIcon = "avatar_side_icon"
        case status
        case remainedTime = "remained_time"
    }
}

struct DailyNoteExpedition: Codable, Equatable {
    let avatarSideIcon: String
    let status: String
    let remainedTimeSeconds: Int

    nonisolated var isComplete: Bool {
        status == "Finished" || remainedTimeSeconds <= 0
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
    let expeditions: [DailyNoteExpedition]

    init(
        fetchedAt: Date,
        currentResin: Int,
        maxResin: Int,
        resinRecoveryTimeSeconds: Int,
        currentHomeCoin: Int,
        maxHomeCoin: Int,
        homeCoinRecoveryTimeSeconds: Int,
        finishedTaskCount: Int,
        totalTaskCount: Int,
        extraTaskRewardReceived: Bool,
        remainingResinDiscounts: Int,
        resinDiscountLimit: Int,
        currentExpeditionCount: Int,
        maxExpeditionCount: Int,
        expeditions: [DailyNoteExpedition]
    ) {
        self.fetchedAt = fetchedAt
        self.currentResin = currentResin
        self.maxResin = maxResin
        self.resinRecoveryTimeSeconds = resinRecoveryTimeSeconds
        self.currentHomeCoin = currentHomeCoin
        self.maxHomeCoin = maxHomeCoin
        self.homeCoinRecoveryTimeSeconds = homeCoinRecoveryTimeSeconds
        self.finishedTaskCount = finishedTaskCount
        self.totalTaskCount = totalTaskCount
        self.extraTaskRewardReceived = extraTaskRewardReceived
        self.remainingResinDiscounts = remainingResinDiscounts
        self.resinDiscountLimit = resinDiscountLimit
        self.currentExpeditionCount = currentExpeditionCount
        self.maxExpeditionCount = maxExpeditionCount
        self.expeditions = expeditions
    }

    enum CodingKeys: String, CodingKey {
        case fetchedAt
        case currentResin
        case maxResin
        case resinRecoveryTimeSeconds
        case currentHomeCoin
        case maxHomeCoin
        case homeCoinRecoveryTimeSeconds
        case finishedTaskCount
        case totalTaskCount
        case extraTaskRewardReceived
        case remainingResinDiscounts
        case resinDiscountLimit
        case currentExpeditionCount
        case maxExpeditionCount
        case expeditions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fetchedAt = try container.decode(Date.self, forKey: .fetchedAt)
        currentResin = try container.decode(Int.self, forKey: .currentResin)
        maxResin = try container.decode(Int.self, forKey: .maxResin)
        resinRecoveryTimeSeconds = try container.decode(Int.self, forKey: .resinRecoveryTimeSeconds)
        currentHomeCoin = try container.decode(Int.self, forKey: .currentHomeCoin)
        maxHomeCoin = try container.decode(Int.self, forKey: .maxHomeCoin)
        homeCoinRecoveryTimeSeconds = try container.decode(Int.self, forKey: .homeCoinRecoveryTimeSeconds)
        finishedTaskCount = try container.decode(Int.self, forKey: .finishedTaskCount)
        totalTaskCount = try container.decode(Int.self, forKey: .totalTaskCount)
        extraTaskRewardReceived = try container.decode(Bool.self, forKey: .extraTaskRewardReceived)
        remainingResinDiscounts = try container.decode(Int.self, forKey: .remainingResinDiscounts)
        resinDiscountLimit = try container.decode(Int.self, forKey: .resinDiscountLimit)
        currentExpeditionCount = try container.decode(Int.self, forKey: .currentExpeditionCount)
        maxExpeditionCount = try container.decode(Int.self, forKey: .maxExpeditionCount)
        expeditions = try container.decodeIfPresent([DailyNoteExpedition].self, forKey: .expeditions) ?? []
    }
}
