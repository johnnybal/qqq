//
//  NotificationsSystem.swift
//  LengLeng
//
//  Created: April 3, 2025
//

import Foundation
import UserNotifications
import SwiftUI
import UIKit

class NotificationsSystem: ObservableObject {
    
    // MARK: - Properties
    @Published var pendingNotifications: [NotificationItem] = []
    @Published var hasPermission: Bool = false
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Notification Types
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
    
    // MARK: - Notification Item Model
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
    
    // MARK: - Initialization
    init() {
        loadNotifications()
        checkPermission()
    }
    
    // MARK: - Permissions
    func requestPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                if granted {
                    self?.scheduleWelcomeNotification()
                    self?.scheduleDailyPollReminder()
                }
            }
            
            if let error = error {
                print("🔔 Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func checkPermission() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Scheduling
    func scheduleWelcomeNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Welcome to LengLeng! 🎉"
        content.body = "Start boosting your friends and discover who's rating you!"
        content.sound = .default
        
        // Schedule for 1 hour after installation
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        let request = UNNotificationRequest(identifier: "welcome", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    func scheduleDailyPollReminder() {
        let content = UNMutableNotificationContent()
        content.title = "New Polls Available 🔥"
        content.body = "Vote now to boost your friends and earn more flames!"
        content.sound = .default
        
        // Create a daily trigger at 4 PM
        var dateComponents = DateComponents()
        dateComponents.hour = 16 // 4 PM
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "dailyPoll", content: content, trigger: trigger)
        notificationCenter.add(request)
    }
    
    func scheduleInviteReminder(expirationTime: TimeInterval = 3600) { // Default 1 hour
        let content = UNMutableNotificationContent()
        content.title = "Your Invites Are Expiring Soon! ⏰"
        content.body = "Don't let your invites go to waste! Invite your friends to LengLeng now."
        content.sound = .default
        
        // Schedule for specified expiration time
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: expirationTime * 0.8, repeats: false)
        let request = UNNotificationRequest(identifier: "inviteReminder", content: content, trigger: trigger)
        
        notificationCenter.add(request)
    }
    
    // MARK: - Poll Selection Notifications
    func sendPollSelectionNotification(selectedBy: String?, pollType: String, isPremiumUser: Bool) {
        // Create notification item
        let title = "Someone picked you! 🔥"
        
        // Different messaging based on poll type
        var body = "You've been selected in a poll! Tap to see which one."
        
        switch pollType {
        case "🌍 Always knows what's going on in the world":
            body = "Someone thinks you're always in the know! Check it out."
        case "🍭 Eye candy":
            body = "Someone's got their eye on you! Find out who thinks you're a treat."
        case "⭐ Best glow up":
            body = "Someone's impressed with your glow up! See what they voted for."
        case "🧋 Wanna get boba together this weekend?":
            body = "Someone wants to hang out with you! Tap to see who."
        default:
            body = "You've been selected in a poll! Tap to see which one."
        }
        
        // For premium users, provide a hint about the sender
        let senderHint = isPremiumUser && selectedBy != nil ? generateSenderHint(name: selectedBy!) : nil
        
        let notificationItem = NotificationItem(
            title: title,
            body: body,
            type: .pollSelection,
            senderHint: senderHint,
            pollId: UUID().uuidString
        )
        
        // Add to local notifications
        addNotification(notificationItem)
        
        // Send push notification
        if hasPermission {
            let content = UNMutableNotificationContent()
            content.title = notificationItem.title
            content.body = notificationItem.body
            content.sound = .default
            
            // Add payload for deep linking
            content.userInfo = [
                "type": NotificationType.pollSelection.rawValue,
                "pollId": notificationItem.pollId ?? ""
            ]
            
            // Immediate notification
            let request = UNNotificationRequest(
                identifier: notificationItem.id,
                content: content,
                trigger: nil
            )
            
            notificationCenter.add(request)
        }
    }
    
    // MARK: - Premium Hint Notifications
    func sendPremiumHintNotification() {
        let notificationItem = NotificationItem(
            title: "Curious who voted for you? 👀",
            body: "Upgrade to Power Mode to get hints about your secret admirers!",
            type: .premiumHint
        )
        
        addNotification(notificationItem)
        
        if hasPermission {
            let content = UNMutableNotificationContent()
            content.title = notificationItem.title
            content.body = notificationItem.body
            content.sound = .default
            
            // Schedule for 24 hours after receiving multiple votes
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false)
            let request = UNNotificationRequest(identifier: notificationItem.id, content: content, trigger: trigger)
            
            notificationCenter.add(request)
        }
    }
    
    // MARK: - Flames Notifications
    func sendFlameReceivedNotification(count: Int) {
        let emoji = count > 5 ? "🔥🔥🔥" : "🔥"
        let title = "You're on fire! \(emoji)"
        let body = "You've received \(count) new flames today. You're popular!"
        
        let notificationItem = NotificationItem(
            title: title,
            body: body,
            type: .flameReceived
        )
        
        addNotification(notificationItem)
        
        if hasPermission {
            let content = UNMutableNotificationContent()
            content.title = notificationItem.title
            content.body = notificationItem.body
            content.sound = .default
            
            // Send notification immediately
            let request = UNNotificationRequest(identifier: notificationItem.id, content: content, trigger: nil)
            
            notificationCenter.add(request)
        }
    }
    
    // MARK: - Helper Methods
    private func generateSenderHint(name: String) -> String {
        // For premium users, provide a subtle hint about the sender
        // without revealing their identity completely
        
        let hints = [
            "Their name starts with \(name.prefix(1))",
            "They're in your class",
            "You've interacted with them this week",
            "They might sit near you",
            "They have a class with you"
        ]
        
        return hints.randomElement() ?? "Someone you know voted for you"
    }
    
    // MARK: - Notification Management
    func addNotification(_ notification: NotificationItem) {
        pendingNotifications.insert(notification, at: 0)
        saveNotifications()
    }
    
    func markAsRead(id: String) {
        if let index = pendingNotifications.firstIndex(where: { $0.id == id }) {
            var notification = pendingNotifications[index]
            let updatedNotification = NotificationItem(
                id: notification.id,
                title: notification.title,
                body: notification.body,
                type: NotificationType(rawValue: notification.type) ?? .pollSelection,
                senderHint: notification.senderHint,
                pollId: notification.pollId,
                timestamp: notification.timestamp,
                isRead: true
            )
            
            pendingNotifications[index] = updatedNotification
            saveNotifications()
        }
    }
    
    func clearAllNotifications() {
        pendingNotifications.removeAll()
        saveNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Persistence
    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(pendingNotifications) {
            userDefaults.set(encoded, forKey: "pendingNotifications")
        }
    }
    
    private func loadNotifications() {
        if let data = userDefaults.data(forKey: "pendingNotifications"),
           let decoded = try? JSONDecoder().decode([NotificationItem].self, from: data) {
            pendingNotifications = decoded
        }
    }
    
    // MARK: - Notification Response
    func handleNotificationResponse(response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        if let typeString = userInfo["type"] as? String,
           let type = NotificationType(rawValue: typeString) {
            
            switch type {
            case .pollSelection:
                // Handle navigation to poll results
                if let pollId = userInfo["pollId"] as? String {
                    // Mark notification as read
                    markAsRead(id: response.notification.request.identifier)
                    
                    // Here you would typically navigate to the poll results
                    // This would be handled by your navigation system
                    print("Should navigate to poll results for ID: \(pollId)")
                }
                
            case .premiumHint:
                // Navigate to premium upgrade page
                print("Should navigate to premium upgrade page")
                
            case .dailyPoll:
                // Navigate to daily polls
                print("Should navigate to daily polls")
                
            case .flameReceived:
                // Navigate to flames dashboard
                print("Should navigate to flames dashboard")
                
            case .inviteReminder:
                // Navigate to invite friends page
                print("Should navigate to invite friends page")
            }
        }
    }
}

// MARK: - SwiftUI View Extension
extension NotificationsSystem {
    // View for displaying a notification inbox
    func NotificationsView() -> some View {
        List {
            ForEach(pendingNotifications) { notification in
                HStack {
                    VStack(alignment: .leading) {
                        Text(notification.title)
                            .font(.headline)
                        
                        Text(notification.body)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let hint = notification.senderHint {
                            Text(hint)
                                .font(.caption)
                                .foregroundColor(.purple)
                                .padding(.top, 2)
                        }
                        
                        Text(notification.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !notification.isRead {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                    }
                }
                .padding(.vertical, 4)
                .onTapGesture {
                    markAsRead(id: notification.id)
                }
            }
        }
    }
}
