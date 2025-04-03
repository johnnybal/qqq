import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var socialGraphService: SocialGraphSystem
    @StateObject private var invitationService: InvitationService
    @State private var showingInviteSheet = false
    
    init() {
        // Initialize with temporary services that will be updated in onAppear
        _invitationService = StateObject(wrappedValue: InvitationService(
            userService: UserService(),
            socialGraphService: SocialGraphSystem()
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Invites Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Your Invites")
                                .font(.headline)
                            
                            Spacer()
                            
                            NavigationLink(destination: InviteHistoryView(invitationService: invitationService)) {
                                Text("View History")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if invitationService.isLoading {
                            ProgressView()
                        } else {
                            Text("\(invitationService.availableInvites) invites remaining")
                                .foregroundColor(.secondary)
                            
                            if !invitationService.recentInvites.isEmpty {
                                ForEach(invitationService.recentInvites.prefix(3)) { invite in
                                    InviteRow(invitation: invite)
                                }
                                
                                if invitationService.recentInvites.count > 3 {
                                    NavigationLink(destination: InviteHistoryView(invitationService: invitationService)) {
                                        Text("View All \(invitationService.recentInvites.count) Invites")
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding(.top, 8)
                                    }
                                }
                            } else {
                                Text("No recent invites")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    
                    // Invite Friends Button
                    Button(action: { showingInviteSheet = true }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Invite Friends")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .sheet(isPresented: $showingInviteSheet) {
                InviteFriendsView(invitationService: invitationService)
            }
        }
        .onAppear {
            // Update the invitation service with the environment objects
            invitationService.updateServices(
                userService: userService,
                socialGraphService: socialGraphService
            )
        }
    }
}

struct InviteRow: View {
    let invitation: Invitation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(invitation.recipientName)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(invitation.message)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(invitation.status.rawValue.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(invitation.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch invitation.status {
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
    HomeView()
        .environmentObject(UserService())
        .environmentObject(SocialGraphSystem())
} 