import Foundation
import FirebaseFirestore

struct VirtualCurrency: Codable, Identifiable {
    let id: String
    let userId: String
    var flames: Int
    var gems: Int
    var lastUpdated: Date
    
    // Computed properties for formatted display
    var formattedFlames: String {
        return "\(flames) 🔥"
    }
    
    var formattedGems: String {
        return "\(gems) 💎"
    }
}

// Transaction types for tracking currency changes
enum CurrencyTransactionType: String, Codable {
    case pollReward = "poll_reward"
    case premiumPurchase = "premium_purchase"
    case featureUnlock = "feature_unlock"
    case dailyBonus = "daily_bonus"
    case streakReward = "streak_reward"
}

// Transaction record for tracking currency changes
struct CurrencyTransaction: Codable, Identifiable {
    let id: String
    let userId: String
    let type: CurrencyTransactionType
    let amount: Int
    let currencyType: CurrencyType
    let timestamp: Date
    let metadata: [String: String] // Additional context about the transaction
    
    var formattedAmount: String {
        let prefix = amount >= 0 ? "+" : ""
        return "\(prefix)\(amount) \(currencyType.symbol)"
    }
}

// Type of currency
enum CurrencyType: String, Codable {
    case flames
    case gems
    
    var symbol: String {
        switch self {
        case .flames: return "🔥"
        case .gems: return "💎"
        }
    }
    
    var name: String {
        switch self {
        case .flames: return "Flames"
        case .gems: return "Gems"
        }
    }
}

// Constants for currency rewards
enum CurrencyRewards {
    static let pollSelection = 5 // Flames earned when selected in a poll
    static let dailyStreakBonus = 10 // Gems earned for maintaining a streak
    static let premiumDailyBonus = 5 // Gems earned daily by premium users
    static let inviteAccepted = 20 // Flames earned when an invite is accepted
    static let featureUnlockCost = 50 // Gems cost to unlock premium features
} 