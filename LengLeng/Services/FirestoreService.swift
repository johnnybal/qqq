import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth

class FirestoreService: ObservableObject {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Compliments
    
    func createCompliment(_ compliment: Compliment) async throws {
        let complimentRef = db.collection("compliments").document()
        try await complimentRef.setData(from: compliment)
    }
    
    func fetchCompliments() async throws -> [Compliment] {
        let snapshot = try await db.collection("compliments")
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: Compliment.self)
        }
    }
    
    // MARK: - User Profile
    
    func createUserProfile(_ profile: UserProfile) async throws {
        let profileRef = db.collection("users").document(profile.id)
        try await profileRef.setData(from: profile)
    }
    
    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        let document = try await db.collection("users").document(userId).getDocument()
        return try document.data(as: UserProfile.self)
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws {
        let profileRef = db.collection("users").document(profile.id)
        try await profileRef.setData(from: profile, merge: true)
    }
    
    // MARK: - Friends System
    
    func sendFriendRequest(to userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let requestRef = db.collection("friend_requests").document()
        try await requestRef.setData([
            "from": currentUserId,
            "to": userId,
            "status": "pending",
            "timestamp": FieldValue.serverTimestamp()
        ])
    }
    
    func acceptFriendRequest(_ requestId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let requestRef = db.collection("friend_requests").document(requestId)
        let request = try await requestRef.getDocument()
        
        guard let fromUserId = request.data()?["from"] as? String else { return }
        
        // Update request status
        try await requestRef.updateData(["status": "accepted"])
        
        // Add to friends list for both users
        try await db.collection("users").document(currentUserId).updateData([
            "friends": FieldValue.arrayUnion([fromUserId])
        ])
        try await db.collection("users").document(fromUserId).updateData([
            "friends": FieldValue.arrayUnion([currentUserId])
        ])
    }
    
    func fetchFriendRequests() async throws -> [FriendRequest] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        let snapshot = try await db.collection("friend_requests")
            .whereField("to", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            try document.data(as: FriendRequest.self)
        }
    }
    
    func fetchFriends() async throws -> [UserProfile] {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
        let userDoc = try await db.collection("users").document(currentUserId).getDocument()
        guard let friendIds = userDoc.data()?["friends"] as? [String] else { return [] }
        
        var friends: [UserProfile] = []
        for friendId in friendIds {
            if let friend = try await fetchUserProfile(userId: friendId) {
                friends.append(friend)
            }
        }
        return friends
    }
    
    // MARK: - Reporting System
    
    func reportContent(_ report: ContentReport) async throws {
        let reportRef = db.collection("reports").document()
        try await reportRef.setData(from: report)
    }
    
    func blockUser(_ userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        try await db.collection("users").document(currentUserId).updateData([
            "blockedUsers": FieldValue.arrayUnion([userId])
        ])
    }
} 