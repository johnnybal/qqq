import Foundation

enum Environment {
    case development
    case staging
    case production
    
    static var current: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}

struct AppConfig {
    static let environment = Environment.current
    
    static var apiBaseURL: String {
        switch environment {
        case .development:
            return "https://dev-api.lengleng.com"
        case .staging:
            return "https://staging-api.lengleng.com"
        case .production:
            return "https://api.lengleng.com"
        }
    }
    
    static var firebaseConfig: [String: Any] {
        switch environment {
        case .development:
            return [
                "analyticsCollectionEnabled": false,
                "messagingAutoInitEnabled": true
            ]
        case .staging:
            return [
                "analyticsCollectionEnabled": true,
                "messagingAutoInitEnabled": true
            ]
        case .production:
            return [
                "analyticsCollectionEnabled": true,
                "messagingAutoInitEnabled": true
            ]
        }
    }
    
    static var notificationCategories: [String: Bool] {
        return [
            "poll_selection": true,
            "daily_poll": true,
            "flame_received": true,
            "premium_hint": true,
            "invite_reminder": true,
            "match": true,
            "boost": true
        ]
    }
} 