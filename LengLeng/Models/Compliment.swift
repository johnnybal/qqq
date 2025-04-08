import Foundation
import FirebaseFirestoreSwift

struct Compliment: Identifiable, Codable {
    @DocumentID var id: String?
    let message: String
    let timestamp: Date
    let isAnonymous: Bool
    let senderId: String?
    var sender: UserProfile?
    let receiverId: String
    var likes: Int
    var reports: Int
    var isHidden: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case message
        case timestamp
        case isAnonymous
        case senderId
        case receiverId
        case likes
        case reports
        case isHidden
    }
    
    init(id: String? = nil,
         message: String,
         timestamp: Date = Date(),
         isAnonymous: Bool = true,
         senderId: String? = nil,
         receiverId: String,
         likes: Int = 0,
         reports: Int = 0,
         isHidden: Bool = false) {
        self.id = id
        self.message = message
        self.timestamp = timestamp
        self.isAnonymous = isAnonymous
        self.senderId = senderId
        self.receiverId = receiverId
        self.likes = likes
        self.reports = reports
        self.isHidden = isHidden
    }
} 