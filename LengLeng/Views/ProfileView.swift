import SwiftUI

struct ProfileView: View {
    @State private var user: User?
    @State private var isLoading = false
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @EnvironmentObject var userService: UserService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let currentUser = user {
                        ProfileHeader(user: currentUser)
                        
                        ProfileStats(user: currentUser)
                        
                        ProfileActions(
                            showingEditProfile: $showingEditProfile,
                            showingSettings: $showingSettings
                        )
                    } else {
                        Text("User not found")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(user: user!)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .task {
                await loadUser()
            }
        }
    }
    
    private func loadUser() async {
        isLoading = true
        do {
            user = try await userService.getCurrentUser()
        } catch {
            print("Error loading user: \(error)")
        }
        isLoading = false
    }
}

struct ProfileHeader: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 12) {
            // TODO: Add profile picture
            Circle()
                .fill(Color.blue)
                .frame(width: 100, height: 100)
            
            Text(user.username)
                .font(.title)
                .fontWeight(.bold)
            
            Text(user.email)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if let bio = user.bio {
                Text(bio)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
    }
}

struct ProfileStats: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 30) {
            StatItem(count: user.connections.count, label: "Friends")
            StatItem(count: user.polls.count, label: "Polls")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let count: Int
    let label: String
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct ProfileActions: View {
    @Binding var showingEditProfile: Bool
    @Binding var showingSettings: Bool
    @EnvironmentObject var userService: UserService
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: { showingEditProfile = true }) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit Profile")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: { showingSettings = true }) {
                HStack {
                    Image(systemName: "gear")
                    Text("Settings")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
            
            Button(action: {
                userService.signOut()
            }) {
                HStack {
                    Image(systemName: "arrow.right.square")
                    Text("Logout")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let user: User
    @State private var username = ""
    @State private var bio = ""
    @State private var isLoading = false
    @EnvironmentObject var userService: UserService
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Username", text: $username)
                    TextField("Bio", text: $bio)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    Task {
                        await saveProfile()
                    }
                }
                .disabled(isLoading || !isValid)
            )
            .onAppear {
                username = user.username
                bio = user.bio ?? ""
            }
        }
    }
    
    private var isValid: Bool {
        !username.isEmpty
    }
    
    private func saveProfile() async {
        isLoading = true
        do {
            var updatedUser = user
            updatedUser.username = username
            updatedUser.bio = bio
            try await userService.updateUser(updatedUser)
            dismiss()
        } catch {
            print("Error updating profile: \(error)")
        }
        isLoading = false
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Preferences")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
} 