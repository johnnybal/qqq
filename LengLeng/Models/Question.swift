import Foundation
import FirebaseFirestoreSwift

struct Question: Identifiable, Codable {
    @DocumentID var id: String?
    let text: String
    let emoji: String
    let category: QuestionCategory
    let options: [String]
    let status: QuestionStatus
    let ageAppropriate: AgeRange
    let genderTarget: GenderTarget
    var engagement: EngagementMetrics
    let schedule: QuestionSchedule
    let createdBy: String
    let createdAt: Date
    let lastModified: Date
    var responses: [String: String] // [userId: selectedOption]
    
    enum QuestionCategory: String, Codable {
        case compliment
        case relationship
        case talent
        case personality
    }
    
    enum QuestionStatus: String, Codable {
        case active
        case draft
        case archived
        case scheduled
    }
    
    enum GenderTarget: String, Codable {
        case all
        case male
        case female
        case nonBinary = "non_binary"
    }
    
    struct AgeRange: Codable {
        let min: Int
        let max: Int
    }
    
    struct EngagementMetrics: Codable {
        var impressions: Int
        var responses: Int
        var responseRate: Double
        var flaggedCount: Int
    }
    
    struct QuestionSchedule: Codable {
        let startDate: Date
        let endDate: Date
        let frequency: ScheduleFrequency
        let timeOfDay: String
        
        enum ScheduleFrequency: String, Codable {
            case daily
            case weekly
            case specialEvent = "special_event"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case emoji
        case category
        case options
        case status
        case ageAppropriate
        case genderTarget
        case engagement
        case schedule
        case createdBy
        case createdAt
        case lastModified
        case responses
    }
    
    init(id: String? = nil,
         text: String,
         emoji: String,
         category: QuestionCategory,
         options: [String],
         status: QuestionStatus = .active,
         ageAppropriate: AgeRange = AgeRange(min: 13, max: 25),
         genderTarget: GenderTarget = .all,
         engagement: EngagementMetrics = EngagementMetrics(impressions: 0, responses: 0, responseRate: 0, flaggedCount: 0),
         schedule: QuestionSchedule,
         createdBy: String,
         createdAt: Date = Date(),
         lastModified: Date = Date()) {
        self.id = id
        self.text = text
        self.emoji = emoji
        self.category = category
        self.options = options
        self.status = status
        self.ageAppropriate = ageAppropriate
        self.genderTarget = genderTarget
        self.engagement = engagement
        self.schedule = schedule
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.responses = [:]
    }
} 