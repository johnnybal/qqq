import Foundation
import FirebaseFirestore

class SocialGraphSystem: ObservableObject {
    @Published var connections: [Connection] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    
    func fetchConnections(for userId: String) {
        isLoading = true
        
        db.collection("connections")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { [weak self] (snapshot, error) in
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error
                    return
                }
                
                if let documents = snapshot?.documents {
                    self?.connections = documents.compactMap { document in
                        guard let data = document.data() as? [String: Any],
                              let connectionId = data["connectionId"] as? String,
                              let type = data["type"] as? String,
                              let timestamp = data["timestamp"] as? Timestamp else {
                            return nil
                        }
                        
                        return Connection(
                            id: document.documentID,
                            userId: userId,
                            connectionId: connectionId,
                            type: ConnectionType(rawValue: type) ?? .friend,
                            timestamp: timestamp.dateValue()
                        )
                    }
                }
            }
    }
    
    func addConnection(userId: String, connectionId: String, type: ConnectionType) {
        let data: [String: Any] = [
            "userId": userId,
            "connectionId": connectionId,
            "type": type.rawValue,
            "timestamp": Timestamp(date: Date())
        ]
        
        db.collection("connections").addDocument(data: data) { [weak self] error in
            if let error = error {
                self?.error = error
            }
        }
    }
    
    func removeConnection(connectionId: String) {
        db.collection("connections").document(connectionId).delete { [weak self] error in
            if let error = error {
                self?.error = error
            }
        }
    }
} 