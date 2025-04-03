import SwiftUI

struct SocialView: View {
    @StateObject private var socialSystem: SocialGraphSystem
    @State private var searchText = ""
    @State private var showingInviteSheet = false
    
    init(userProfileSystem: UserProfileSystem) {
        _socialSystem = StateObject(wrappedValue: SocialGraphSystem(userProfileSystem: userProfileSystem))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Friend Suggestions
                    SuggestionListView(socialSystem: socialSystem)
                        .padding(.top)
                    
                    // Friends List
                    VStack(alignment: .leading) {
                        Text("Friends")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if socialSystem.friends.isEmpty {
                            EmptyFriendsView()
                        } else {
                            FriendListView(socialSystem: socialSystem)
                        }
                    }
                }
            }
            .navigationTitle("Social")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingInviteSheet = true
                    }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search friends")
            .sheet(isPresented: $showingInviteSheet) {
                InviteFriendsView(socialSystem: socialSystem)
            }
            .onAppear {
                socialSystem.refreshContactsAndSuggestions()
            }
        }
    }
}

struct SuggestionListView: View {
    @ObservedObject var socialSystem: SocialGraphSystem
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Suggested Friends")
                .font(.headline)
                .padding(.horizontal)
            
            if socialSystem.friendSuggestions.isEmpty {
                Text("No suggestions available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(socialSystem.friendSuggestions.prefix(10)) { suggestion in
                            SuggestionCardView(suggestion: suggestion, socialSystem: socialSystem)
                                .frame(width: 160)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct SuggestionCardView: View {
    let suggestion: SocialGraphSystem.FriendSuggestion
    @ObservedObject var socialSystem: SocialGraphSystem
    @State private var showingAlert = false
    
    var body: some View {
        VStack(alignment: .leading) {
            // Profile picture
            ZStack {
                if let profileURL = suggestion.profilePictureURL,
                   let imageData = try? Data(contentsOf: profileURL),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 160, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .overlay(
                            Image(systemName: "person.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60)
                                .foregroundColor(.gray)
                        )
                }
                
                // Match score badge
                VStack {
                    HStack {
                        Spacer()
                        Text("\(suggestion.matchScore)%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(suggestion.matchScore > 70 ? Color.green : Color.blue)
                                    .opacity(0.9)
                            )
                            .foregroundColor(.white)
                            .padding(8)
                    }
                    Spacer()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.fullName)
                    .font(.headline)
                    .lineLimit(1)
                
                if let username = suggestion.username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Match reason
                HStack {
                    switch suggestion.matchReason {
                    case .sharedContacts:
                        Image(systemName: "person.2.fill")
                        Text("\(suggestion.sharedFriendCount) mutual")
                    case .friendOfFriend:
                        Image(systemName: "person.2.fill")
                        Text("Friend of friend")
                    case .sameSchool:
                        Image(systemName: "building.2")
                        Text("Same school")
                    case .contactMatch:
                        Image(systemName: "phone.fill")
                        Text("In contacts")
                    case .recentlyJoined:
                        Image(systemName: "clock.fill")
                        Text("New user")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Button(action: {
                    showingAlert = true
                }) {
                    Text("Add Friend")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
        .alert("Add Friend", isPresented: $showingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                _ = socialSystem.addFriend(from: suggestion)
            }
        } message: {
            Text("Would you like to add \(suggestion.fullName) as a friend?")
        }
    }
}

struct FriendListView: View {
    @ObservedObject var socialSystem: SocialGraphSystem
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(socialSystem.friends) { friend in
                FriendRowView(friend: friend, socialSystem: socialSystem)
                    .contextMenu {
                        Button(action: {
                            socialSystem.toggleFavorite(friendId: friend.id)
                        }) {
                            Label(friend.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                  systemImage: friend.isFavorite ? "star.slash" : "star")
                        }
                        
                        Button(role: .destructive, action: {
                            socialSystem.removeFriend(id: friend.id)
                        }) {
                            Label("Remove Friend", systemImage: "person.badge.minus")
                        }
                    }
            }
        }
    }
}

struct FriendRowView: View {
    let friend: SocialGraphSystem.Friend
    @ObservedObject var socialSystem: SocialGraphSystem
    
    var body: some View {
        HStack {
            // Profile picture
            if let profileURL = friend.profilePictureURL,
               let imageData = try? Data(contentsOf: profileURL),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            // Friend details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(friend.fullName)
                        .font(.headline)
                    
                    if friend.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                if let username = friend.username {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Flames count
            HStack(spacing: 2) {
                Text("\(friend.flamesCount)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("🔥")
                    .font(.subheadline)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.orange.opacity(0.2))
            .cornerRadius(10)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.white)
    }
}

struct EmptyFriendsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Friends Yet")
                .font(.headline)
            
            Text("Add friends to start polling and sharing moments together!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct InviteFriendsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var socialSystem: SocialGraphSystem
    @State private var searchText = ""
    
    var filteredContacts: [SocialGraphSystem.ContactToInvite] {
        if searchText.isEmpty {
            return socialSystem.contactsToInvite
        }
        return socialSystem.contactsToInvite.filter { contact in
            contact.name.lowercased().contains(searchText.lowercased()) ||
            contact.phoneNumber.contains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if socialSystem.isLoadingContacts {
                    ProgressView("Loading contacts...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else if let error = socialSystem.contactsLoadError {
                    Text(error)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else if filteredContacts.isEmpty {
                    Text("No contacts found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredContacts) { contact in
                        ContactRowView(contact: contact, socialSystem: socialSystem)
                    }
                }
            }
            .navigationTitle("Invite Friends")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .searchable(text: $searchText, prompt: "Search contacts")
            .onAppear {
                if !socialSystem.isContactPermissionGranted {
                    socialSystem.requestContactAccess { granted in
                        if !granted {
                            socialSystem.contactsLoadError = "Please enable contact access in Settings"
                        }
                    }
                }
            }
        }
    }
}

struct ContactRowView: View {
    let contact: SocialGraphSystem.ContactToInvite
    @ObservedObject var socialSystem: SocialGraphSystem
    @State private var isInviting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        HStack {
            // Contact picture
            if let thumbnailData = contact.thumbnailImageData,
               let uiImage = UIImage(data: thumbnailData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }
            
            // Contact details
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                
                Text(contact.phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Invite button
            Button(action: {
                isInviting = true
                if socialSystem.sendInvite(to: contact) {
                    alertMessage = "Invitation sent to \(contact.name)"
                } else {
                    alertMessage = "Failed to send invitation. Please try again."
                }
                showingAlert = true
                isInviting = false
            }) {
                if isInviting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Invite")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(isInviting)
        }
        .alert("Invite Status", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
} 