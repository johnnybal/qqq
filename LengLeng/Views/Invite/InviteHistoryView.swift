import SwiftUI

struct InviteHistoryView: View {
    @ObservedObject var invitationService: InvitationService
    @State private var selectedFilter: InvitationStatus?
    
    var filteredInvites: [Invitation] {
        guard let filter = selectedFilter else {
            return invitationService.recentInvites
        }
        return invitationService.recentInvites.filter { $0.status == filter }
    }
    
    var body: some View {
        List {
            // Filter Section
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedFilter == nil,
                            action: { selectedFilter = nil }
                        )
                        
                        ForEach(InvitationStatus.allCases, id: \.self) { status in
                            FilterChip(
                                title: status.rawValue.capitalized,
                                isSelected: selectedFilter == status,
                                action: { selectedFilter = status }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 8)
            }
            
            // Invites List
            Section {
                if invitationService.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else if filteredInvites.isEmpty {
                    Text("No invites found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredInvites) { invite in
                        InviteHistoryRow(invitation: invite)
                    }
                }
            }
        }
        .navigationTitle("Invite History")
        .refreshable {
            // Refresh invites
            invitationService.loadRecentInvites()
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct InviteHistoryRow: View {
    let invitation: Invitation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(invitation.recipientName)
                        .font(.headline)
                    Text(invitation.recipientPhone)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: invitation.status)
            }
            
            // Message
            if !invitation.message.isEmpty {
                Text(invitation.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Footer
            HStack {
                // Tracking Info
                if let tracking = invitation.trackingData {
                    HStack(spacing: 16) {
                        if tracking.clickedAt != nil {
                            Label("Clicked", systemImage: "hand.tap")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        if tracking.installedAt != nil {
                            Label("Installed", systemImage: "checkmark.circle")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        if tracking.reminderCount > 0 {
                            Label("\(tracking.reminderCount) Reminders", systemImage: "bell")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                // Time
                Text(invitation.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatusBadge: View {
    let status: InvitationStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor.opacity(0.2))
            .foregroundColor(backgroundColor)
            .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .sent:
            return .blue
        case .clicked:
            return .orange
        case .installed:
            return .green
        case .expired:
            return .red
        }
    }
}

#Preview {
    NavigationView {
        InviteHistoryView(invitationService: InvitationService(
            userService: UserService(),
            socialGraphService: SocialGraphSystem()
        ))
    }
} 