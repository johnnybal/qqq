import Foundation
import FirebaseFirestore
import FirebaseAuth
import MessageUI

enum InvitationError: LocalizedError {
    case notAuthenticated
    case noInvitesRemaining
    case invalidContact
    case sendFailed
    case firebaseError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to send invites"
        case .noInvitesRemaining:
            return "You have no invites remaining"
        case .invalidContact:
            return "Invalid contact information"
        case .sendFailed:
            return "Failed to send invitation"
        case .firebaseError(let error):
            return "Firebase error: \(error.localizedDescription)"
        }
    }
}

class InvitationService: ObservableObject {
    private let db = Firestore.firestore()
    private var userService: UserService
    private var socialGraphService: SocialGraphSystem
    private let messagingService: MessagingService
    private let analyticsService = AnalyticsService.shared
    
    @Published var availableInvites: Int = 0
    @Published var recentInvites: [Invitation] = []
    @Published var isLoading = false
    @Published var error: InvitationError?
    
    init(userService: UserService, socialGraphService: SocialGraphSystem, messagingService: MessagingService = MessagingService()) {
        self.userService = userService
        self.socialGraphService = socialGraphService
        self.messagingService = messagingService
        loadAvailableInvites()
        loadRecentInvites()
    }
    
    func updateServices(userService: UserService, socialGraphService: SocialGraphSystem) {
        self.userService = userService
        self.socialGraphService = socialGraphService
        fetchRecentInvites()
    }
    
    // MARK: - Invite Management
    
    func loadAvailableInvites() {
        guard let userId = Auth.auth().currentUser?.uid else {
            error = .notAuthenticated
            return
        }
        
        isLoading = true
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = .firebaseError(error)
                    return
                }
                
                if let data = snapshot?.data(),
                   let invites = data["availableInvites"] as? Int {
                    self?.availableInvites = invites
                }
            }
        }
    }
    
    private func loadRecentInvites() {
        guard let userId = Auth.auth().currentUser?.uid else {
            error = .notAuthenticated
            return
        }
        
        isLoading = true
        db.collection("invitations")
            .whereField("senderId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.error = .firebaseError(error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    let invites = documents.compactMap { Invitation.from($0) }
                    self?.recentInvites = invites
                }
            }
    }
    
    func fetchRecentInvites() {
        guard let userId = userService.currentUser?.id else { return }
        
        isLoading = true
        
        db.collection("invitations")
            .whereField("senderId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 10)
            .getDocuments { [weak self] (snapshot, error) in
                self?.isLoading = false
                
                if let error = error {
                    self?.error = .firebaseError(error)
                    return
                }
                
                if let documents = snapshot?.documents {
                    self?.recentInvites = documents.compactMap { document in
                        guard let data = document.data() as? [String: Any],
                              let recipientName = data["recipientName"] as? String,
                              let message = data["message"] as? String,
                              let statusRaw = data["status"] as? String,
                              let createdAt = data["createdAt"] as? Timestamp else {
                            return nil
                        }
                        
                        return Invitation(
                            id: document.documentID,
                            recipientName: recipientName,
                            message: message,
                            status: InvitationStatus(rawValue: statusRaw) ?? .sent,
                            createdAt: createdAt.dateValue()
                        )
                    }
                }
            }
    }
    
    // MARK: - Retry Logic
    
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0
    
    private func retryOperation<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                    continue
                }
            }
        }
        
        throw lastError ?? InvitationError.sendFailed
    }
    
    // MARK: - Daily Limits
    
    private let maxDailyInvites = 10
    
    private func checkDailyLimit() async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let snapshot = try await db.collection("invitations")
            .whereField("senderId", isEqualTo: userId)
            .whereField("createdAt", isGreaterThan: Timestamp(date: today))
            .count
            .getAggregation()
        
        let todayCount = Int(truncating: snapshot.count)
        
        if todayCount >= maxDailyInvites {
            throw InvitationError.noInvitesRemaining
        }
    }
    
    func sendInvite(to contact: ContactToInvite, message: String? = nil) async throws -> Bool {
        return try await retryOperation {
            guard let userId = Auth.auth().currentUser?.uid else {
                throw InvitationError.notAuthenticated
            }
            
            // Check daily limit
            try await checkDailyLimit()
            
            // Check if user has available invites
            if availableInvites <= 0 {
                throw InvitationError.noInvitesRemaining
            }
            
            // Validate contact
            guard !contact.phoneNumber.isEmpty else {
                throw InvitationError.invalidContact
            }
            
            do {
                // Generate invite link
                let inviteLink = try await socialGraphService.generateInviteLink(for: userId)
                
                // Create invitation record
                let invitation = Invitation(
                    id: UUID().uuidString,
                    senderId: userId,
                    recipientPhone: contact.phoneNumber,
                    recipientName: contact.name,
                    message: message ?? generateMessage(for: contact),
                    messageVariant: determineMessageVariant(),
                    createdAt: Date(),
                    expiresAt: Date().addingTimeInterval(24 * 60 * 60), // 24 hours
                    status: .sent,
                    trackingData: Invitation.TrackingData(reminderCount: 0)
                )
                
                // Save to Firestore
                try await db.collection("invitations").document(invitation.id).setData(invitation.dictionary)
                
                // Update user's available invites
                try await db.collection("users").document(userId).updateData([
                    "availableInvites": FieldValue.increment(Int64(-1))
                ])
                
                // Send the actual invitation
                let success = try await messagingService.sendInvitation(
                    to: contact,
                    message: invitation.message,
                    inviteLink: inviteLink
                )
                
                if success {
                    // Track analytics
                    analyticsService.trackInvitationSent(
                        invitationId: invitation.id,
                        recipientType: contact.school != nil ? "school" : "general"
                    )
                    
                    // Update local state
                    await MainActor.run {
                        availableInvites -= 1
                        recentInvites.insert(invitation, at: 0)
                    }
                } else {
                    throw InvitationError.sendFailed
                }
                
                return success
            } catch let error as InvitationError {
                throw error
            } catch {
                throw InvitationError.firebaseError(error)
            }
        }
    }
    
    // MARK: - Message Generation
    
    private func generateMessage(for contact: ContactToInvite) -> String {
        let templates = [
            "Someone at \(contact.school ?? "your school") picked you on LengLeng 🔥 Find out who!",
            "\(Int.random(in: 3...8)) people from \(contact.school ?? "your school") have rated you on LengLeng. See what they said!",
            "Someone thinks you're 👑 at \(contact.school ?? "your school"). Find out who on LengLeng!",
            "Your crush might be waiting for you on LengLeng 👀"
        ]
        
        return templates.randomElement() ?? templates[0]
    }
    
    private func determineMessageVariant() -> Invitation.MessageVariant {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour >= 5 && hour < 12 {
            return .timeBased // Morning variant
        } else if hour >= 12 && hour < 17 {
            return .timeBased // Afternoon variant
        } else {
            return .standard // Evening variant
        }
    }
    
    // MARK: - Invitation Tracking
    
    func trackInvitationClick(invitationId: String) async throws {
        try await db.collection("invitations").document(invitationId).updateData([
            "status": InvitationStatus.clicked.rawValue,
            "trackingData.clickedAt": Timestamp(date: Date())
        ])
        
        // Track analytics
        analyticsService.trackInvitationClicked(invitationId: invitationId)
    }
    
    func trackInvitationInstall(invitationId: String) async throws {
        try await db.collection("invitations").document(invitationId).updateData([
            "status": InvitationStatus.installed.rawValue,
            "trackingData.installedAt": Timestamp(date: Date())
        ])
        
        // Track analytics
        analyticsService.trackInvitationInstalled(invitationId: invitationId)
        
        // Award bonus invites for successful installation
        if let userId = Auth.auth().currentUser?.uid {
            try await db.collection("users").document(userId).updateData([
                "availableInvites": FieldValue.increment(Int64(5))
            ])
            
            // Track reward analytics
            analyticsService.trackRewardsAwarded(
                userId: userId,
                rewardType: "installation_bonus",
                amount: 5
            )
            
            await MainActor.run {
                availableInvites += 5
            }
        }
    }
    
    // MARK: - Invitation Reminders
    
    func sendReminder(for invitation: Invitation) async throws {
        guard invitation.trackingData?.reminderCount ?? 0 < 2 else { return }
        
        let reminderMessage = "Don't forget to check out LengLeng! Someone is waiting to connect with you 🔥"
        
        try await messagingService.sendInvitation(
            to: ContactToInvite(
                id: UUID().uuidString,
                name: invitation.recipientName,
                phoneNumber: invitation.recipientPhone,
                school: nil
            ),
            message: reminderMessage,
            inviteLink: try await socialGraphService.generateInviteLink(for: invitation.senderId)
        )
        
        try await db.collection("invitations").document(invitation.id).updateData([
            "trackingData.lastReminderSent": Timestamp(date: Date()),
            "trackingData.reminderCount": FieldValue.increment(Int64(1))
        ])
        
        // Track analytics
        analyticsService.trackReminderSent(
            invitationId: invitation.id,
            reminderCount: invitation.trackingData?.reminderCount ?? 0 + 1
        )
    }
    
    // MARK: - Invitation Rewards
    
    func awardInvitesForStreak(days: Int) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let invitesToAward = (days / 3) * 2 // 2 invites for every 3 days
        
        try await db.collection("users").document(userId).updateData([
            "availableInvites": FieldValue.increment(Int64(invitesToAward))
        ])
        
        // Track analytics
        analyticsService.trackRewardsAwarded(
            userId: userId,
            rewardType: "streak_bonus",
            amount: invitesToAward
        )
        
        await MainActor.run {
            availableInvites += invitesToAward
        }
    }
    
    func awardInvitesForPremium() async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        try await db.collection("users").document(userId).updateData([
            "availableInvites": FieldValue.increment(Int64(3))
        ])
        
        // Track analytics
        analyticsService.trackRewardsAwarded(
            userId: userId,
            rewardType: "premium_bonus",
            amount: 3
        )
        
        await MainActor.run {
            availableInvites += 3
        }
    }
} 