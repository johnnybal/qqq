import Foundation
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let email: String
    var displayName: String
    var username: String
    var profileImageURL: String?
    var gender: String?
    var age: Int?
    var schoolName: String?
    var grade: Int?
    var hasCompletedOnboarding: Bool
    var friends: [String]
    var receivedCompliments: [Compliment]
    var sentCompliments: [Compliment]
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case username
        case profileImageURL
        case gender
        case age
        case schoolName
        case grade
        case hasCompletedOnboarding
        case friends
        case receivedCompliments
        case sentCompliments
    }
}

struct Compliment: Codable {
    let message: String
    let timestamp: Date
    let isAnonymous: Bool
    let senderId: String?
} 