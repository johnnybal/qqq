import Foundation
import FirebaseFirestore
import FirebaseAuth
import MessageUI

class InvitationService: ObservableObject {
    private let db = Firestore.firestore()
    private var userService: UserService
    private var socialGraphService: SocialGraphSystem
    private let messagingService: MessagingService
    
    @Published var availableInvites: Int = 0
    @Published var recentInvites: [Invitation] = []
    @Published var isLoading = false
    
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
    }
    
    // MARK: - Invite Management
    
    func loadAvailableInvites() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let data = snapshot?.data(),
               let invites = data["availableInvites"] as? Int {
                DispatchQueue.main.async {
                    self?.availableInvites = invites
                }
            }
        }
    }
    
    private func loadRecentInvites() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("invitations")
            .whereField("senderId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: 20)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let invites = documents.compactMap { Invitation.from($0) }
                DispatchQueue.main.async {
                    self?.recentInvites = invites
                }
            }
    }
    
    func sendInvite(to contact: ContactToInvite, message: String? = nil) async throws -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "InvitationService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Check if user has available invites
        if availableInvites <= 0 {
            throw NSError(domain: "InvitationService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No invites remaining"])
        }
        
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
            // Update local state
            await MainActor.run {
                availableInvites -= 1
                recentInvites.insert(invitation, at: 0)
            }
        }
        
        return success
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
    }
    
    func trackInvitationInstall(invitationId: String) async throws {
        try await db.collection("invitations").document(invitationId).updateData([
            "status": InvitationStatus.installed.rawValue,
            "trackingData.installedAt": Timestamp(date: Date())
        ])
        
        // Award bonus invites for successful installation
        if let userId = Auth.auth().currentUser?.uid {
            try await db.collection("users").document(userId).updateData([
                "availableInvites": FieldValue.increment(Int64(5))
            ])
            
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
    }
    
    // MARK: - Invitation Rewards
    
    func awardInvitesForStreak(days: Int) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let invitesToAward = (days / 3) * 2 // 2 invites for every 3 days
        
        try await db.collection("users").document(userId).updateData([
            "availableInvites": FieldValue.increment(Int64(invitesToAward))
        ])
        
        await MainActor.run {
            availableInvites += invitesToAward
        }
    }
    
    func awardInvitesForPremium() async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        try await db.collection("users").document(userId).updateData([
            "availableInvites": FieldValue.increment(Int64(3))
        ])
        
        await MainActor.run {
            availableInvites += 3
        }
    }
} 