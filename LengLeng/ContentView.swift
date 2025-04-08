import SwiftUI

struct Compliment: Identifiable {
    let id = UUID()
    let message: String
    let timestamp: Date
    let isAnonymous: Bool
}

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    @State private var selectedTab = 0
    @State private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if let user = authService.currentUser {
                if !hasCompletedOnboarding {
                    OnboardingView()
                        .onAppear {
                            // Check if user has completed onboarding
                            hasCompletedOnboarding = user.hasCompletedOnboarding
                        }
                } else {
                    TabView(selection: $selectedTab) {
                        QuestionView(user: user)
                            .tabItem {
                                Label("Questions", systemImage: "questionmark.circle")
                            }
                            .tag(0)
                        
                        FriendsView(user: user)
                            .tabItem {
                                Label("Friends", systemImage: "person.2")
                            }
                            .tag(1)
                        
                        ProfileView(user: user)
                            .tabItem {
                                Label("Profile", systemImage: "person")
                            }
                            .tag(2)
                    }
                }
            } else {
                AuthenticationView()
            }
        }
    }
}

struct ComplimentCard: View {
    let compliment: Compliment
    @EnvironmentObject private var firestoreService: FirestoreService
    @State private var isLiked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(compliment.message)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
            
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.gray)
                Text("Anonymous")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    // Handle like action
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .gray)
                }
                
                Text(compliment.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
        }
    }
}

struct NewComplimentView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authService: AuthenticationService
    @EnvironmentObject private var firestoreService: FirestoreService
    @Binding var compliments: [Compliment]
    @State private var newCompliment = ""
    @State private var isAnonymous = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Send a compliment")
                    .font(.headline)
                    .padding()
                
                TextEditor(text: $newCompliment)
                    .frame(height: 150)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                
                Toggle("Send anonymously", isOn: $isAnonymous)
                    .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: {
                    Task {
                        await sendCompliment()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Send")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .cornerRadius(12)
                    }
                }
                .disabled(isLoading || newCompliment.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Compliment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sendCompliment() async {
        guard let userId = authService.user?.uid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let compliment = Compliment(
                message: newCompliment,
                senderId: userId,
                receiverId: userId, // For now, sending to self. Will update with friend selection
                isAnonymous: isAnonymous
            )
            
            try await firestoreService.createCompliment(compliment)
            compliments.insert(compliment, at: 0)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct ProfileView: View {
    let user: UserProfile
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        if let imageURL = user.profileImageURL {
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image.resizable()
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(user.displayName)
                                .font(.headline)
                            Text("@\(user.username)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            if let gender = user.gender {
                                Text(gender.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Section("Question Stats") {
                    HStack {
                        Text("Questions Answered")
                        Spacer()
                        Text("\(user.questionStats.totalAnswered)")
                    }
                    
                    HStack {
                        Text("Correct Answers")
                        Spacer()
                        Text("\(user.questionStats.totalCorrect)")
                    }
                    
                    if let favoriteCategory = user.questionStats.favoriteCategory {
                        HStack {
                            Text("Favorite Category")
                            Spacer()
                            Text(favoriteCategory.capitalized)
                        }
                    }
                    
                    if let lastAnswered = user.questionStats.lastAnswered {
                        HStack {
                            Text("Last Answered")
                            Spacer()
                            Text(lastAnswered, style: .relative)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section("Friends") {
                    HStack {
                        Text("Total Friends")
                        Spacer()
                        Text("\(user.friends.count)")
                    }
                }
                
                if let bio = user.bio {
                    Section("About") {
                        Text(bio)
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService.shared)
        .environmentObject(FirestoreService.shared)
} 