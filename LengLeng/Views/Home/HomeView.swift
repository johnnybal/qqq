import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var socialGraphService: SocialGraphSystem
    @StateObject private var invitationService: InvitationService
    @State private var showingInviteSheet = false
    @State private var showingSubscriptionStatus = false
    
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
                    // Subscription Status Button
                    Button(action: { showingSubscriptionStatus = true }) {
                        HStack {
                            Image(systemName: subscriptionService.isSubscribed ? "star.fill" : "star")
                                .foregroundColor(subscriptionService.isSubscribed ? .yellow : .gray)
                            
                            Text(subscriptionService.isSubscribed ? "Power Mode Active" : "Upgrade to Power Mode")
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Invites Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Invites")
                            .font(.headline)
                        
                        if invitationService.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else if invitationService.recentInvites.isEmpty {
                            Text("No invites sent yet")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(invitationService.recentInvites) { invite in
                                InviteRow(invite: invite)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Invite Friends Button
                    Button(action: { showingInviteSheet = true }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Invite Friends")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Home")
            .sheet(isPresented: $showingInviteSheet) {
                InviteFriendsView(invitationService: invitationService)
            }
            .sheet(isPresented: $showingSubscriptionStatus) {
                SubscriptionStatusView()
            }
            .onAppear {
                invitationService.updateServices(userService: userService, socialGraphService: socialGraphService)
            }
        }
    }
}

struct InviteRow: View {
    let invite: Invitation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(invite.recipientName)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(invite.message)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(invite.status.rawValue.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(invite.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch invite.status {
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