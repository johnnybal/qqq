import Foundation
import FirebaseFirestoreSwift

struct ContentReport: Identifiable, Codable {
    @DocumentID var id: String?
    let reporterId: String
    let contentId: String
    let contentType: String // "compliment", "comment", etc.
    let reason: String
    let timestamp: Date
    var status: String = "pending" // pending, reviewed, resolved
    
    enum CodingKeys: String, CodingKey {
        case id
        case reporterId
        case contentId
        case contentType
        case reason
        case timestamp
        case status
    }
} 