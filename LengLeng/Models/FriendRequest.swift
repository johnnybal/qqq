import Foundation
import FirebaseFirestoreSwift

struct FriendRequest: Identifiable, Codable {
    @DocumentID var id: String?
    let from: String
    let to: String
    let status: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case from
        case to
        case status
        case timestamp
    }
} 