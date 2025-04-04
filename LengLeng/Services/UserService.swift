import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        auth.addStateDidChangeListener { [weak self] (_, user) in
            if let user = user {
                self?.fetchUserData(userId: user.uid)
            } else {
                self?.currentUser = nil
            }
        }
    }
    
    func fetchUserData(userId: String) {
        isLoading = true
        
        db.collection("users").document(userId).getDocument { [weak self] (document, error) in
            self?.isLoading = false
            
            if let error = error {
                self?.error = error
                return
            }
            
            if let document = document, document.exists,
               let data = document.data() {
                self?.currentUser = User(
                    id: userId,
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                )
            }
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        
        auth.signIn(withEmail: email, password: password) { [weak self] (result, error) in
            self?.isLoading = false
            
            if let error = error {
                self?.error = error
                return
            }
            
            if let userId = result?.user.uid {
                self?.fetchUserData(userId: userId)
            }
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            currentUser = nil
        } catch {
            self.error = error
        }
    }
} 