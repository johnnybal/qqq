import Foundation
import FirebaseFirestoreSwift

struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String?
    let email: String
    var username: String
    var displayName: String
    var bio: String?
    var profileImageURL: String?
    var friends: [String] = []
    var blockedUsers: [String] = []
    var isAnonymous: Bool = false
    var createdAt: Date
    var lastActive: Date
    var isAdmin: Bool
    var gender: String?
    var age: Int?
    var questionStats: QuestionStats
    
    struct QuestionStats: Codable {
        var totalAnswered: Int
        var totalCorrect: Int
        var favoriteCategory: String?
        var lastAnswered: Date?
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case displayName
        case bio
        case profileImageURL
        case friends
        case blockedUsers
        case isAnonymous
        case createdAt
        case lastActive
        case isAdmin
        case gender
        case age
        case questionStats
    }
    
    init(id: String? = nil,
         email: String,
         username: String,
         displayName: String,
         bio: String? = nil,
         profileImageURL: String? = nil,
         createdAt: Date = Date(),
         lastActive: Date = Date(),
         isAdmin: Bool = false,
         gender: String? = nil,
         age: Int? = nil) {
        self.id = id
        self.email = email
        self.username = username
        self.displayName = displayName
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.lastActive = lastActive
        self.isAdmin = isAdmin
        self.gender = gender
        self.age = age
        self.questionStats = QuestionStats(totalAnswered: 0, totalCorrect: 0)
    }
} 