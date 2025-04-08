import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        auth.addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.fetchUser(userId: user.uid)
            } else {
                self?.currentUser = nil
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await auth.signIn(withEmail: email, password: password)
        try await fetchUser(userId: result.user.uid)
    }
    
    func signUp(email: String, password: String, displayName: String, username: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        
        let newUser = User(
            email: email,
            displayName: displayName,
            username: username,
            profileImageURL: nil,
            gender: nil,
            age: nil,
            schoolName: nil,
            grade: nil,
            hasCompletedOnboarding: false,
            friends: [],
            receivedCompliments: [],
            sentCompliments: []
        )
        
        try await db.collection("users").document(result.user.uid).setData(from: newUser)
        try await fetchUser(userId: result.user.uid)
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func updateOnboardingStatus(completed: Bool) async throws {
        guard let userId = currentUser?.id else { return }
        
        try await db.collection("users").document(userId).updateData([
            "hasCompletedOnboarding": completed
        ])
        
        try await fetchUser(userId: userId)
    }
    
    private func fetchUser(userId: String) async throws {
        let document = try await db.collection("users").document(userId).getDocument()
        currentUser = try document.data(as: User.self)
    }
} 