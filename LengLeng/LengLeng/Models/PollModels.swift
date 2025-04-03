import Foundation

struct Poll: Codable {
    let id: String
    let question: String
    let options: [PollOption]
    let creatorId: String
    let createdAt: Date
    let expiresAt: Date
    let isAnonymous: Bool
    let category: PollCategory
    var totalVotes: Int
    var boostCount: Int
    var matchType: String?
    var matchedUsers: [String]?
    
    enum PollCategory: String, Codable, CaseIterable {
        case general
        case school
        case sports
        case entertainment
        case dating
        case other
    }
}

struct PollOption: Codable {
    let id: String
    let text: String
    var voteCount: Int
}

struct PollVote: Codable {
    let pollId: String
    let userId: String
    let optionId: String
    let timestamp: Date
} 