import Foundation
import FirebaseAnalytics
import FirebaseFirestore
import FirebaseAuth

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    private let db = Firestore.firestore()
    
    @Published var userEngagementMetrics: UserEngagementMetrics?
    @Published var pollAnalytics: PollAnalytics?
    @Published var conversionMetrics: ConversionMetrics?
    @Published var retentionAnalysis: RetentionAnalysis?
    @Published var currencyAnalytics: CurrencyAnalytics?
    @Published var schoolAnalytics: [SchoolAnalytics] = []
    
    private init() {}
    
    // MARK: - Analytics Collection
    
    func trackUserEngagement() async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let userRef = db.collection("users").document(userId)
        let sessionRef = db.collection("user_sessions").document()
        
        let sessionData: [String: Any] = [
            "userId": userId,
            "timestamp": Timestamp(),
            "sessionDuration": 0, // Will be updated when session ends
            "actions": []
        ]
        
        try await sessionRef.setData(sessionData)
        
        // Update user's last active timestamp
        try await userRef.updateData([
            "lastActive": Timestamp(),
            "totalSessions": FieldValue.increment(Int64(1))
        ])
    }
    
    func trackPollParticipation(pollId: String, selectedUserId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let pollRef = db.collection("polls").document(pollId)
        let voteRef = db.collection("poll_votes").document()
        
        let voteData: [String: Any] = [
            "pollId": pollId,
            "userId": userId,
            "selectedUserId": selectedUserId,
            "timestamp": Timestamp()
        ]
        
        try await voteRef.setData(voteData)
        
        // Update poll statistics
        try await pollRef.updateData([
            "totalVotes": FieldValue.increment(Int64(1)),
            "lastVoteTimestamp": Timestamp()
        ])
        
        // Track in Firebase Analytics
        Analytics.logEvent("poll_participation", parameters: [
            "poll_id": pollId,
            "selected_user_id": selectedUserId
        ])
    }
    
    func trackInviteSent(recipientId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let inviteRef = db.collection("invites").document()
        
        let inviteData: [String: Any] = [
            "senderId": userId,
            "recipientId": recipientId,
            "timestamp": Timestamp(),
            "status": "sent"
        ]
        
        try await inviteRef.setData(inviteData)
        
        // Track in Firebase Analytics
        Analytics.logEvent("invite_sent", parameters: [
            "recipient_id": recipientId
        ])
    }
    
    func trackPremiumConversion() async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let userRef = db.collection("users").document(userId)
        
        try await userRef.updateData([
            "isPremium": true,
            "premiumConversionDate": Timestamp()
        ])
        
        // Track in Firebase Analytics
        Analytics.logEvent("premium_conversion", parameters: [
            "user_id": userId
        ])
    }
    
    // MARK: - Analytics Retrieval
    
    func fetchAnalytics(timeRange: AnalyticsTimeRange) async throws {
        let startDate = getStartDate(for: timeRange)
        
        async let engagementMetrics = fetchUserEngagementMetrics(since: startDate)
        async let pollMetrics = fetchPollAnalytics(since: startDate)
        async let conversionMetrics = fetchConversionMetrics(since: startDate)
        async let retentionMetrics = fetchRetentionAnalysis(since: startDate)
        async let currencyMetrics = fetchCurrencyAnalytics(since: startDate)
        async let schoolMetrics = fetchSchoolAnalytics(since: startDate)
        
        let (engagement, polls, conversions, retention, currency, schools) = try await (
            engagementMetrics,
            pollMetrics,
            conversionMetrics,
            retentionMetrics,
            currencyMetrics,
            schoolMetrics
        )
        
        DispatchQueue.main.async {
            self.userEngagementMetrics = engagement
            self.pollAnalytics = polls
            self.conversionMetrics = conversions
            self.retentionAnalysis = retention
            self.currencyAnalytics = currency
            self.schoolAnalytics = schools
        }
    }
    
    private func fetchUserEngagementMetrics(since date: Date) async throws -> UserEngagementMetrics {
        let snapshot = try await db.collection("user_sessions")
            .whereField("timestamp", isGreaterThan: Timestamp(date: date))
            .getDocuments()
        
        let sessions = snapshot.documents
        let uniqueUsers = Set(sessions.compactMap { $0.data()["userId"] as? String })
        
        let totalDuration = sessions.compactMap { $0.data()["sessionDuration"] as? TimeInterval }.reduce(0, +)
        let averageDuration = sessions.isEmpty ? 0 : totalDuration / Double(sessions.count)
        
        return UserEngagementMetrics(
            dailyActiveUsers: uniqueUsers.count,
            weeklyActiveUsers: uniqueUsers.count,
            monthlyActiveUsers: uniqueUsers.count,
            averageSessionDuration: averageDuration,
            sessionsPerUser: Double(sessions.count) / Double(uniqueUsers.count),
            retentionRate: 0.8, // This would need more complex calculation
            churnRate: 0.2, // This would need more complex calculation
            date: Date()
        )
    }
    
    private func fetchPollAnalytics(since date: Date) async throws -> PollAnalytics {
        let snapshot = try await db.collection("polls")
            .whereField("timestamp", isGreaterThan: Timestamp(date: date))
            .getDocuments()
        
        let polls = snapshot.documents
        let totalVotes = polls.compactMap { $0.data()["totalVotes"] as? Int }.reduce(0, +)
        
        return PollAnalytics(
            totalPolls: polls.count,
            activePolls: polls.filter { ($0.data()["isActive"] as? Bool) ?? false }.count,
            totalVotes: totalVotes,
            averageVotesPerPoll: polls.isEmpty ? 0 : Double(totalVotes) / Double(polls.count),
            mostPopularPoll: "Sample Poll", // This would need more complex calculation
            leastPopularPoll: "Sample Poll", // This would need more complex calculation
            date: Date()
        )
    }
    
    private func fetchConversionMetrics(since date: Date) async throws -> ConversionMetrics {
        let usersSnapshot = try await db.collection("users")
            .whereField("createdAt", isGreaterThan: Timestamp(date: date))
            .getDocuments()
        
        let premiumSnapshot = try await db.collection("users")
            .whereField("isPremium", isEqualTo: true)
            .whereField("premiumConversionDate", isGreaterThan: Timestamp(date: date))
            .getDocuments()
        
        let invitesSnapshot = try await db.collection("invites")
            .whereField("timestamp", isGreaterThan: Timestamp(date: date))
            .getDocuments()
        
        let acceptedInvites = invitesSnapshot.documents.filter { ($0.data()["status"] as? String) == "accepted" }
        
        return ConversionMetrics(
            totalSignups: usersSnapshot.documents.count,
            premiumConversions: premiumSnapshot.documents.count,
            inviteAcceptanceRate: invitesSnapshot.documents.isEmpty ? 0 : Double(acceptedInvites.count) / Double(invitesSnapshot.documents.count),
            dailyActiveToPremiumRate: usersSnapshot.documents.isEmpty ? 0 : Double(premiumSnapshot.documents.count) / Double(usersSnapshot.documents.count),
            date: Date()
        )
    }
    
    private func fetchRetentionAnalysis(since date: Date) async throws -> RetentionAnalysis {
        // This would need more complex calculation based on user cohorts
        return RetentionAnalysis(
            cohortDate: date,
            cohortSize: 100,
            day1Retention: 0.8,
            day7Retention: 0.6,
            day30Retention: 0.4,
            returningUsers: 80
        )
    }
    
    private func fetchCurrencyAnalytics(since date: Date) async throws -> CurrencyAnalytics {
        let transactionsSnapshot = try await db.collection("currency_transactions")
            .whereField("timestamp", isGreaterThan: Timestamp(date: date))
            .getDocuments()
        
        let transactions = transactionsSnapshot.documents
        let flamesTransactions = transactions.filter { ($0.data()["currencyType"] as? String) == "flames" }
        let gemsTransactions = transactions.filter { ($0.data()["currencyType"] as? String) == "gems" }
        
        let totalFlames = flamesTransactions.compactMap { $0.data()["amount"] as? Int }.reduce(0, +)
        let totalGems = gemsTransactions.compactMap { $0.data()["amount"] as? Int }.reduce(0, +)
        
        let uniqueUsers = Set(transactions.compactMap { $0.data()["userId"] as? String })
        
        return CurrencyAnalytics(
            totalFlamesAwarded: totalFlames,
            totalGemsAwarded: totalGems,
            averageFlamesPerUser: uniqueUsers.isEmpty ? 0 : Double(totalFlames) / Double(uniqueUsers.count),
            averageGemsPerUser: uniqueUsers.isEmpty ? 0 : Double(totalGems) / Double(uniqueUsers.count),
            date: Date()
        )
    }
    
    private func fetchSchoolAnalytics(since date: Date) async throws -> [SchoolAnalytics] {
        let schoolsSnapshot = try await db.collection("schools").getDocuments()
        
        var schoolAnalytics: [SchoolAnalytics] = []
        
        for schoolDoc in schoolsSnapshot.documents {
            let schoolId = schoolDoc.documentID
            let schoolName = schoolDoc.data()["name"] as? String ?? "Unknown School"
            
            let usersSnapshot = try await db.collection("users")
                .whereField("schoolId", isEqualTo: schoolId)
                .whereField("createdAt", isGreaterThan: Timestamp(date: date))
                .getDocuments()
            
            let premiumSnapshot = try await db.collection("users")
                .whereField("schoolId", isEqualTo: schoolId)
                .whereField("isPremium", isEqualTo: true)
                .getDocuments()
            
            let activeSnapshot = try await db.collection("users")
                .whereField("schoolId", isEqualTo: schoolId)
                .whereField("lastActive", isGreaterThan: Timestamp(date: date))
                .getDocuments()
            
            let analytics = SchoolAnalytics(
                schoolId: schoolId,
                schoolName: schoolName,
                totalUsers: usersSnapshot.documents.count,
                activeUsers: activeSnapshot.documents.count,
                premiumUsers: premiumSnapshot.documents.count,
                averageEngagementScore: 0.8, // This would need more complex calculation
                date: Date()
            )
            
            schoolAnalytics.append(analytics)
        }
        
        return schoolAnalytics
    }
    
    private func getStartDate(for timeRange: AnalyticsTimeRange) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case .day:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            return Date.distantPast
        }
    }
} 