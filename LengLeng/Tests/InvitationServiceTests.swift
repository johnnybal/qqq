import XCTest
import FirebaseFirestore
import FirebaseAuth
@testable import LengLeng

class InvitationServiceTests: XCTestCase {
    var invitationService: InvitationService!
    var mockUserService: UserService!
    var mockSocialGraphService: SocialGraphSystem!
    var mockMessagingService: MessagingService!
    
    override func setUp() {
        super.setUp()
        mockUserService = UserService()
        mockSocialGraphService = SocialGraphSystem()
        mockMessagingService = MessagingService()
        invitationService = InvitationService(
            userService: mockUserService,
            socialGraphService: mockSocialGraphService,
            messagingService: mockMessagingService
        )
    }
    
    override func tearDown() {
        invitationService = nil
        mockUserService = nil
        mockSocialGraphService = nil
        mockMessagingService = nil
        super.tearDown()
    }
    
    func testSendInviteWithNoInvitesRemaining() async {
        // Given
        invitationService.availableInvites = 0
        let contact = ContactToInvite(id: "1", name: "Test User", phoneNumber: "1234567890", school: nil)
        
        // When/Then
        do {
            _ = try await invitationService.sendInvite(to: contact)
            XCTFail("Expected error to be thrown")
        } catch InvitationError.noInvitesRemaining {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSendInviteWithInvalidContact() async {
        // Given
        invitationService.availableInvites = 5
        let contact = ContactToInvite(id: "1", name: "Test User", phoneNumber: "", school: nil)
        
        // When/Then
        do {
            _ = try await invitationService.sendInvite(to: contact)
            XCTFail("Expected error to be thrown")
        } catch InvitationError.invalidContact {
            // Success
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testTrackInvitationClick() async {
        // Given
        let invitationId = "test-invitation-id"
        
        // When/Then
        do {
            try await invitationService.trackInvitationClick(invitationId: invitationId)
            // Success - no error thrown
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testTrackInvitationInstall() async {
        // Given
        let invitationId = "test-invitation-id"
        
        // When/Then
        do {
            try await invitationService.trackInvitationInstall(invitationId: invitationId)
            // Success - no error thrown
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testSendReminder() async {
        // Given
        let invitation = Invitation(
            id: "test-invitation-id",
            senderId: "test-sender-id",
            recipientPhone: "1234567890",
            recipientName: "Test User",
            message: "Test message",
            messageVariant: .standard,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(24 * 60 * 60),
            status: .sent,
            trackingData: Invitation.TrackingData(reminderCount: 0)
        )
        
        // When/Then
        do {
            try await invitationService.sendReminder(for: invitation)
            // Success - no error thrown
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testAwardInvitesForStreak() async {
        // Given
        let days = 6 // Should award 4 invites (2 for every 3 days)
        
        // When/Then
        do {
            try await invitationService.awardInvitesForStreak(days: days)
            // Success - no error thrown
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testAwardInvitesForPremium() async {
        // When/Then
        do {
            try await invitationService.awardInvitesForPremium()
            // Success - no error thrown
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
} 