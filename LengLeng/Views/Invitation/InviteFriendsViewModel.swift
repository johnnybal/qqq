import SwiftUI

class InviteFriendsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedContacts: Set<ContactToInvite> = []
    @Published var availableInvites = 0
    @Published var recentInvites: [Invitation] = []
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showInviteHistory = false
    @Published var showCustomMessage = false
    @Published var customMessage: String = ""
    @Published var isLoading = false
    
    private let invitationService: InvitationService
    private let contactService: ContactService
    private var allContacts: [ContactToInvite] = []
    
    var filteredContacts: [ContactToInvite] {
        if searchText.isEmpty {
            return allContacts
        }
        return contactService.searchContacts(query: searchText)
    }
    
    var canSendInvites: Bool {
        !selectedContacts.isEmpty && selectedContacts.count <= availableInvites
    }
    
    init(invitationService: InvitationService = InvitationService(userService: UserService(), socialGraphService: SocialGraphSystem()),
         contactService: ContactService = ContactService()) {
        self.invitationService = invitationService
        self.contactService = contactService
        loadContacts()
        loadInviteData()
    }
    
    private func loadContacts() {
        Task {
            do {
                try await contactService.requestAccess()
                try await contactService.loadContacts()
                await MainActor.run {
                    allContacts = contactService.contacts
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadInviteData() {
        availableInvites = invitationService.availableInvites
        recentInvites = invitationService.recentInvites
    }
    
    func filterContacts(_ filter: ContactFilter) {
        allContacts = contactService.filterContacts(by: filter)
    }
    
    func toggleContact(_ contact: ContactToInvite) {
        if selectedContacts.contains(contact) {
            selectedContacts.remove(contact)
        } else {
            if selectedContacts.count < availableInvites {
                selectedContacts.insert(contact)
            } else {
                showError = true
                errorMessage = "You don't have enough invites remaining"
            }
        }
    }
    
    func sendInvites() {
        Task {
            do {
                isLoading = true
                for contact in selectedContacts {
                    try await invitationService.sendInvite(to: contact, message: customMessage)
                }
                await MainActor.run {
                    selectedContacts.removeAll()
                    customMessage = ""
                    loadInviteData()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
} 