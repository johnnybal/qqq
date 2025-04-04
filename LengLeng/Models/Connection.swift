import Foundation

enum ConnectionType: String, Codable {
    case friend
    case follower
    case blocked
}

struct Connection: Identifiable, Codable {
    let id: String
    let userId: String
    let connectionId: String
    let type: ConnectionType
    let timestamp: Date
} 