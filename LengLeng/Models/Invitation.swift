import Foundation
import FirebaseFirestore

enum InvitationStatus: String, CaseIterable, Codable {
    case sent
    case clicked
    case installed
    case expired
}

struct Invitation: Identifiable, Codable {
    let id: String
    let senderId: String
    let recipientPhone: String
    let recipientName: String
    let message: String
    let messageVariant: MessageVariant
    let createdAt: Date
    let expiresAt: Date
    var status: InvitationStatus
    var trackingData: TrackingData?
    
    enum MessageVariant: String, Codable {
        case standard
        case timeBased
    }
    
    struct TrackingData: Codable {
        var clickedAt: Date?
        var installedAt: Date?
        var reminderCount: Int
        var lastReminderSent: Date?
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "senderId": senderId,
            "recipientPhone": recipientPhone,
            "recipientName": recipientName,
            "message": message,
            "messageVariant": messageVariant.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "expiresAt": Timestamp(date: expiresAt),
            "status": status.rawValue
        ]
        
        if let tracking = trackingData {
            var trackingDict: [String: Any] = [
                "reminderCount": tracking.reminderCount
            ]
            
            if let clickedAt = tracking.clickedAt {
                trackingDict["clickedAt"] = Timestamp(date: clickedAt)
            }
            
            if let installedAt = tracking.installedAt {
                trackingDict["installedAt"] = Timestamp(date: installedAt)
            }
            
            if let lastReminderSent = tracking.lastReminderSent {
                trackingDict["lastReminderSent"] = Timestamp(date: lastReminderSent)
            }
            
            dict["trackingData"] = trackingDict
        }
        
        return dict
    }
    
    static func from(_ document: QueryDocumentSnapshot) -> Invitation? {
        let data = document.data()
        
        guard let id = data["id"] as? String,
              let senderId = data["senderId"] as? String,
              let recipientPhone = data["recipientPhone"] as? String,
              let recipientName = data["recipientName"] as? String,
              let message = data["message"] as? String,
              let messageVariantRaw = data["messageVariant"] as? String,
              let messageVariant = MessageVariant(rawValue: messageVariantRaw),
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
              let expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue(),
              let statusRaw = data["status"] as? String,
              let status = InvitationStatus(rawValue: statusRaw)
        else {
            return nil
        }
        
        var trackingData: TrackingData?
        if let trackingDict = data["trackingData"] as? [String: Any] {
            trackingData = TrackingData(
                clickedAt: (trackingDict["clickedAt"] as? Timestamp)?.dateValue(),
                installedAt: (trackingDict["installedAt"] as? Timestamp)?.dateValue(),
                reminderCount: trackingDict["reminderCount"] as? Int ?? 0,
                lastReminderSent: (trackingDict["lastReminderSent"] as? Timestamp)?.dateValue()
            )
        }
        
        return Invitation(
            id: id,
            senderId: senderId,
            recipientPhone: recipientPhone,
            recipientName: recipientName,
            message: message,
            messageVariant: messageVariant,
            createdAt: createdAt,
            expiresAt: expiresAt,
            status: status,
            trackingData: trackingData
        )
    }
} 