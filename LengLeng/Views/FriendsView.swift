import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var firestoreService: FirestoreService
    @State private var friends: [UserProfile] = []
    @State private var friendRequests: [FriendRequest] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingFriendRequestSheet = false
    
    var body: some View {
        NavigationView {
            List {
                if !friendRequests.isEmpty {
                    Section("Friend Requests") {
                        ForEach(friendRequests) { request in
                            FriendRequestRow(request: request)
                        }
                    }
                }
                
                Section("Friends") {
                    if friends.isEmpty {
                        Text("No friends yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(friends) { friend in
                            FriendRow(friend: friend)
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFriendRequestSheet = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingFriendRequestSheet) {
                AddFriendView()
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        Task {
            do {
                async let friendsTask = firestoreService.fetchFriends()
                async let requestsTask = firestoreService.fetchFriendRequests()
                
                let (fetchedFriends, fetchedRequests) = try await (friendsTask, requestsTask)
                
                await MainActor.run {
                    self.friends = fetchedFriends
                    self.friendRequests = fetchedRequests
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct FriendRequestRow: View {
    @EnvironmentObject private var firestoreService: FirestoreService
    let request: FriendRequest
    @State private var isLoading = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Friend Request")
                    .font(.headline)
                Text("From: \(request.from)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isLoading {
                ProgressView()
            } else {
                Button("Accept") {
                    acceptRequest()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private func acceptRequest() {
        guard let requestId = request.id else { return }
        isLoading = true
        
        Task {
            do {
                try await firestoreService.acceptFriendRequest(requestId)
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct FriendRow: View {
    let friend: UserProfile
    
    var body: some View {
        HStack {
            if let imageURL = friend.profileImageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 40, height: 40)
            }
            
            VStack(alignment: .leading) {
                Text(friend.displayName)
                    .font(.headline)
                Text(friend.username)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firestoreService: FirestoreService
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Send") { sendRequest() }
                    .disabled(username.isEmpty || isLoading)
            )
        }
    }
    
    private func sendRequest() {
        isLoading = true
        
        Task {
            do {
                // First, find the user by username
                let usersRef = Firestore.firestore().collection("users")
                let query = usersRef.whereField("username", isEqualTo: username)
                let snapshot = try await query.getDocuments()
                
                guard let userDoc = snapshot.documents.first,
                      let userId = userDoc.data()["id"] as? String else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                }
                
                try await firestoreService.sendFriendRequest(to: userId)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
} 