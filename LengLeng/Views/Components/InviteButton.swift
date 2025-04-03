import SwiftUI

struct InviteButton: View {
    @StateObject private var invitationService = InvitationService(userService: UserService(), socialGraphService: SocialGraphSystem())
    @State private var showInviteSheet = false
    
    var body: some View {
        Button(action: { showInviteSheet = true }) {
            HStack {
                Image(systemName: "person.badge.plus")
                Text("Invite")
                if invitationService.availableInvites > 0 {
                    Text("(\(invitationService.availableInvites))")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.white)
            .cornerRadius(20)
        }
        .sheet(isPresented: $showInviteSheet) {
            InviteFriendsView()
        }
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        InviteButton()
    }
} 