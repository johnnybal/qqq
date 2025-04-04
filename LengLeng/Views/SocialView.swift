import SwiftUI

struct SocialView: View {
    @State private var selectedTab = 0
    @State private var friends: [User] = []
    @State private var pendingRequests: [User] = []
    @State private var isLoading = false
    @EnvironmentObject var socialService: SocialService
    
    var body: some View {
        VStack {
            Picker("View", selection: $selectedTab) {
                Text("Friends").tag(0)
                Text("Requests").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView(selection: $selectedTab) {
                    FriendsList(friends: friends)
                        .tag(0)
                    
                    RequestsList(requests: pendingRequests)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .navigationTitle("Social")
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        isLoading = true
        do {
            friends = try await socialService.getFriends()
            pendingRequests = try await socialService.getPendingRequests()
        } catch {
            print("Error loading social data: \(error)")
        }
        isLoading = false
    }
}

struct FriendsList: View {
    let friends: [User]
    
    var body: some View {
        List {
            if friends.isEmpty {
                Text("No friends yet")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(friends) { friend in
                    FriendRow(friend: friend)
                }
            }
        }
    }
}

struct RequestsList: View {
    let requests: [User]
    @EnvironmentObject var socialService: SocialService
    
    var body: some View {
        List {
            if requests.isEmpty {
                Text("No pending requests")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(requests) { request in
                    RequestRow(user: request)
                }
            }
        }
    }
}

struct FriendRow: View {
    let friend: User
    
    var body: some View {
        HStack {
            // TODO: Add profile picture
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(friend.username)
                    .font(.headline)
                Text(friend.isOnline ? "Online" : "Offline")
                    .font(.caption)
                    .foregroundColor(friend.isOnline ? .green : .gray)
            }
            
            Spacer()
            
            Button(action: {
                // TODO: Open chat
            }) {
                Image(systemName: "message")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RequestRow: View {
    let user: User
    @EnvironmentObject var socialService: SocialService
    
    var body: some View {
        HStack {
            // TODO: Add profile picture
            Circle()
                .fill(Color.blue)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Text(user.username)
                    .font(.headline)
                Text("Wants to be friends")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack {
                Button(action: {
                    Task {
                        try? await socialService.acceptRequest(from: user.id)
                    }
                }) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
                
                Button(action: {
                    Task {
                        try? await socialService.rejectRequest(from: user.id)
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
} 