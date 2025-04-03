import SwiftUI
import ContactsUI

struct InviteFriendsView: View {
    @StateObject private var viewModel = InviteFriendsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Invite Credits Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(viewModel.availableInvites)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                            Text("Invites Remaining")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: { viewModel.showInviteHistory = true }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(15)
                    
                    // Search Bar
                    SearchBar(text: $viewModel.searchText)
                        .padding(.horizontal)
                    
                    // Quick Select Options
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            QuickSelectButton(title: "Top Matches", action: { viewModel.filterContacts(.topMatches) })
                            QuickSelectButton(title: "School Friends", action: { viewModel.filterContacts(.school) })
                            QuickSelectButton(title: "Recent Contacts", action: { viewModel.filterContacts(.recent) })
                        }
                        .padding(.horizontal)
                    }
                    
                    // Contacts List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.filteredContacts) { contact in
                                ContactRow(contact: contact, isSelected: viewModel.selectedContacts.contains(contact)) {
                                    viewModel.toggleContact(contact)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 15) {
                        Button(action: { viewModel.sendInvites() }) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Send \(viewModel.selectedContacts.count) Invites")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.canSendInvites ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                        .disabled(!viewModel.canSendInvites)
                        
                        Button(action: { viewModel.showCustomMessage = true }) {
                            Text("Customize Message")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showInviteHistory) {
                InviteHistoryView(invites: viewModel.recentInvites)
            }
            .sheet(isPresented: $viewModel.showCustomMessage) {
                CustomMessageView(message: $viewModel.customMessage)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

// MARK: - Supporting Views

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search contacts", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

struct QuickSelectButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(20)
        }
    }
}

struct ContactRow: View {
    let contact: ContactToInvite
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Contact Avatar
                if let image = contact.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    if let school = contact.school {
                        Text(school)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(15)
        }
    }
}

// MARK: - View Model

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
    
    private let invitationService: InvitationService
    private var allContacts: [ContactToInvite] = []
    
    var filteredContacts: [ContactToInvite] {
        if searchText.isEmpty {
            return Array(allContacts)
        }
        return allContacts.filter { contact in
            contact.name.localizedCaseInsensitiveContains(searchText) ||
            contact.school?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var canSendInvites: Bool {
        !selectedContacts.isEmpty && selectedContacts.count <= availableInvites
    }
    
    init(invitationService: InvitationService = InvitationService(userService: UserService(), socialGraphService: SocialGraphSystem())) {
        self.invitationService = invitationService
        loadContacts()
        loadInviteData()
    }
    
    private func loadContacts() {
        // Implementation will depend on your contact access implementation
        // This is a placeholder
        allContacts = []
    }
    
    private func loadInviteData() {
        availableInvites = invitationService.availableInvites
        recentInvites = invitationService.recentInvites
    }
    
    func filterContacts(_ filter: ContactFilter) {
        switch filter {
        case .topMatches:
            // Implement top matches logic
            break
        case .school:
            // Implement school filter logic
            break
        case .recent:
            // Implement recent contacts logic
            break
        }
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
                for contact in selectedContacts {
                    try await invitationService.sendInvite(to: contact, message: customMessage)
                }
                selectedContacts.removeAll()
                customMessage = ""
                loadInviteData()
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

enum ContactFilter {
    case topMatches
    case school
    case recent
} 