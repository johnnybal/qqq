import Foundation

struct NotificationItem: Identifiable, Codable {
    let id: String
    let title: String
    let body: String
    let type: String
    let senderHint: String?
    let pollId: String?
    let timestamp: Date
    var isRead: Bool
    var data: [String: Any]?
    
    init(id: String = UUID().uuidString, 
         title: String, 
         body: String, 
         type: NotificationType, 
         senderHint: String? = nil, 
         pollId: String? = nil, 
         timestamp: Date = Date(), 
         isRead: Bool = false,
         data: [String: Any]? = nil) {
        self.id = id
        self.title = title
        self.body = body
        self.type = type.rawValue
        self.senderHint = senderHint
        self.pollId = pollId
        self.timestamp = timestamp
        self.isRead = isRead
        self.data = data
    }
}

enum NotificationType: String {
    case pollSelection = "poll_selection"
    case dailyPoll = "daily_poll"
    case flameReceived = "flame_received"
    case premiumHint = "premium_hint"
    case inviteReminder = "invite_reminder"
    case match = "match"
    case boost = "boost"
    
    var categoryIdentifier: String {
        return "category_\(rawValue)"
    }
} 