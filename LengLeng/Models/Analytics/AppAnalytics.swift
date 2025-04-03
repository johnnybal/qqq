import Foundation
import FirebaseFirestore

// MARK: - User Engagement Metrics
struct UserEngagementMetrics: Codable {
    let dailyActiveUsers: Int
    let weeklyActiveUsers: Int
    let monthlyActiveUsers: Int
    let averageSessionDuration: TimeInterval
    let sessionsPerUser: Double
    let retentionRate: Double // Percentage of users who return
    let churnRate: Double // Percentage of users who stop using the app
    let date: Date
    
    var formattedRetentionRate: String {
        return String(format: "%.1f%%", retentionRate * 100)
    }
    
    var formattedChurnRate: String {
        return String(format: "%.1f%%", churnRate * 100)
    }
    
    var formattedAverageSessionDuration: String {
        let minutes = Int(averageSessionDuration / 60)
        let seconds = Int(averageSessionDuration.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Poll Analytics
struct PollAnalytics: Codable {
    let totalPolls: Int
    let activePolls: Int
    let totalVotes: Int
    let averageVotesPerPoll: Double
    let mostPopularPoll: String
    let leastPopularPoll: String
    let date: Date
    
    var participationRate: Double {
        guard totalPolls > 0 else { return 0 }
        return Double(totalVotes) / Double(totalPolls)
    }
    
    var formattedParticipationRate: String {
        return String(format: "%.1f%%", participationRate * 100)
    }
}

// MARK: - Conversion Metrics
struct ConversionMetrics: Codable {
    let totalSignups: Int
    let premiumConversions: Int
    let inviteAcceptanceRate: Double
    let dailyActiveToPremiumRate: Double
    let date: Date
    
    var formattedInviteAcceptanceRate: String {
        return String(format: "%.1f%%", inviteAcceptanceRate * 100)
    }
    
    var formattedPremiumConversionRate: String {
        return String(format: "%.1f%%", dailyActiveToPremiumRate * 100)
    }
}

// MARK: - Retention Analysis
struct RetentionAnalysis: Codable {
    let cohortDate: Date
    let cohortSize: Int
    let day1Retention: Double
    let day7Retention: Double
    let day30Retention: Double
    let returningUsers: Int
    
    var formattedDay1Retention: String {
        return String(format: "%.1f%%", day1Retention * 100)
    }
    
    var formattedDay7Retention: String {
        return String(format: "%.1f%%", day7Retention * 100)
    }
    
    var formattedDay30Retention: String {
        return String(format: "%.1f%%", day30Retention * 100)
    }
}

// MARK: - Currency Analytics
struct CurrencyAnalytics: Codable {
    let totalFlamesAwarded: Int
    let totalGemsAwarded: Int
    let averageFlamesPerUser: Double
    let averageGemsPerUser: Double
    let date: Date
    
    var formattedAverageFlames: String {
        return String(format: "%.1f 🔥", averageFlamesPerUser)
    }
    
    var formattedAverageGems: String {
        return String(format: "%.1f 💎", averageGemsPerUser)
    }
}

// MARK: - School Analytics
struct SchoolAnalytics: Codable {
    let schoolId: String
    let schoolName: String
    let totalUsers: Int
    let activeUsers: Int
    let premiumUsers: Int
    let averageEngagementScore: Double
    let date: Date
    
    var engagementRate: Double {
        guard totalUsers > 0 else { return 0 }
        return Double(activeUsers) / Double(totalUsers)
    }
    
    var formattedEngagementRate: String {
        return String(format: "%.1f%%", engagementRate * 100)
    }
    
    var premiumConversionRate: Double {
        guard totalUsers > 0 else { return 0 }
        return Double(premiumUsers) / Double(totalUsers)
    }
    
    var formattedPremiumConversionRate: String {
        return String(format: "%.1f%%", premiumConversionRate * 100)
    }
}

// MARK: - Time Range
enum AnalyticsTimeRange: String, Codable {
    case day = "day"
    case week = "week"
    case month = "month"
    case year = "year"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .day: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        case .year: return "This Year"
        case .all: return "All Time"
        }
    }
} 