import Foundation
import Contacts
import SwiftUI
import CoreLocation

class SocialGraphSystem: ObservableObject {
    // MARK: - Properties
    @Published var friends: [Friend] = []
    @Published var friendSuggestions: [FriendSuggestion] = []
    @Published var contactsToInvite: [ContactToInvite] = []
    @Published var isLoadingContacts: Bool = false
    @Published var contactsLoadError: String?
    @Published var isContactPermissionGranted: Bool = false
    
    // Dependencies
    private let userProfileSystem: UserProfileSystem
    private let contactStore = CNContactStore()
    private let userDefaults = UserDefaults.standard
    private let locationManager = CLLocationManager()
    
    // Constants
    private let MAX_SUGGESTIONS = 100
    private let CONTACTS_REFRESH_INTERVAL: TimeInterval = 86400 // 24 hours in seconds
    
    // API endpoints (replace with your actual API URLs)
    private let friendsEndpoint = "https://api.lengleng.app/friends"
    private let suggestionsEndpoint = "https://api.lengleng.app/suggestions"
    
    // MARK: - Models
    struct Friend: Identifiable, Codable, Equatable {
        let id: String
        let userId: String
        var firstName: String
        var lastName: String
        var username: String?
        var profilePictureURL: URL?
        var schoolId: String?
        var schoolName: String?
        var flamesCount: Int
        var friendshipDate: Date
        var isFavorite: Bool
        var lastInteractionDate: Date?
        var polledCount: Int
        var receivedPollCount: Int
        
        static func == (lhs: Friend, rhs: Friend) -> Bool {
            return lhs.id == rhs.id
        }
        
        var fullName: String {
            return "\(firstName) \(lastName)"
        }
        
        var displayName: String {
            return username ?? firstName
        }
    }
    
    struct FriendSuggestion: Identifiable, Codable {
        let id: String
        let userId: String
        var firstName: String
        var lastName: String
        var username: String?
        var profilePictureURL: URL?
        var schoolId: String?
        var schoolName: String?
        var flamesCount: Int?
        var matchScore: Int // Higher score means better suggestion
        var matchReason: MatchReason
        var sharedFriends: [String]? // List of user IDs
        var sharedFriendCount: Int
        
        var fullName: String {
            return "\(firstName) \(lastName)"
        }
        
        var displayName: String {
            return username ?? firstName
        }
    }
    
    struct ContactToInvite: Identifiable, Codable {
        let id: String = UUID().uuidString
        let name: String
        let phoneNumber: String
        let appUsersWithContact: Int // Number of app users who have this contact
        let thumbnailImageData: Data?
        
        var priorityScore: Int {
            return appUsersWithContact
        }
    }
    
    enum MatchReason: String, Codable {
        case sharedContacts = "shared_contacts"
        case friendOfFriend = "friend_of_friend"
        case sameSchool = "same_school"
        case contactMatch = "contact_match"
        case recentlyJoined = "recently_joined"
    }
    
    enum FriendshipStatus: String, Codable {
        case friend
        case suggested
        case notConnected
    }
    
    // MARK: - Initialization
    init(userProfileSystem: UserProfileSystem) {
        self.userProfileSystem = userProfileSystem
        checkContactPermission()
        loadFriendsFromDefaults()
        loadSuggestionsFromDefaults()
        checkForContactsRefresh()
    }
    
    // MARK: - Permissions
    func checkContactPermission() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        isContactPermissionGranted = (status == .authorized)
    }
    
    func requestContactAccess(completion: @escaping (Bool) -> Void) {
        contactStore.requestAccess(for: .contacts) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isContactPermissionGranted = granted
                completion(granted)
                
                if granted {
                    self?.fetchContactsAndUpdateSuggestions()
                }
            }
        }
    }
    
    // MARK: - Contacts & Suggestions
    func refreshContactsAndSuggestions() {
        guard isContactPermissionGranted else {
            self.contactsLoadError = "Contact permission not granted"
            return
        }
        
        fetchContactsAndUpdateSuggestions()
        userDefaults.set(Date(), forKey: "lastContactsRefreshDate")
    }
    
    private func checkForContactsRefresh() {
        if let lastRefreshDate = userDefaults.object(forKey: "lastContactsRefreshDate") as? Date {
            let timeElapsed = Date().timeIntervalSince(lastRefreshDate)
            if timeElapsed > CONTACTS_REFRESH_INTERVAL {
                refreshContactsAndSuggestions()
            }
        } else {
            // First time - refresh right away
            refreshContactsAndSuggestions()
        }
    }
    
    private func fetchContactsAndUpdateSuggestions() {
        isLoadingContacts = true
        contactsLoadError = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Define which contact properties to fetch
            let keys = [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactPhoneNumbersKey,
                CNContactThumbnailImageDataKey
            ]
            
            let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
            var contactsList: [CNContact] = []
            
            do {
                try self.contactStore.enumerateContacts(with: request) { contact, _ in
                    contactsList.append(contact)
                }
                
                // Process contacts on main thread
                DispatchQueue.main.async {
                    self.processContacts(contactsList)
                    self.isLoadingContacts = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.contactsLoadError = "Failed to load contacts: \(error.localizedDescription)"
                    self.isLoadingContacts = false
                }
            }
        }
    }
    
    private func processContacts(_ contacts: [CNContact]) {
        // In a real app, you would send contacts to your backend for matching
        // For demo purposes, we'll generate mock data
        
        var contactsToInvite: [ContactToInvite] = []
        
        for contact in contacts {
            // Skip contacts without phone numbers
            guard let phoneNumber = contact.phoneNumbers.first?.value.stringValue else {
                continue
            }
            
            let formattedNumber = formatPhoneNumber(phoneNumber)
            
            let contactToInvite = ContactToInvite(
                name: "\(contact.givenName) \(contact.familyName)",
                phoneNumber: formattedNumber,
                appUsersWithContact: Int.random(in: 0...10), // Mock data
                thumbnailImageData: contact.thumbnailImageData
            )
            
            contactsToInvite.append(contactToInvite)
        }
        
        // Sort by priority score
        contactsToInvite.sort { $0.priorityScore > $1.priorityScore }
        
        // Update published property
        self.contactsToInvite = contactsToInvite
        
        // Save to defaults
        saveContactsToInviteToDefaults()
        
        // Generate friend suggestions
        generateFriendSuggestions(from: contacts)
    }
    
    private func generateFriendSuggestions(from contacts: [CNContact]) {
        // In a real app, you would send contacts to your backend and receive suggestions
        // For demo purposes, we'll generate mock suggestions
        
        var suggestions: [FriendSuggestion] = []
        
        // Generate mock suggestions from contact "matches"
        for i in 0..<min(15, contacts.count) {
            let contact = contacts[i]
            let firstName = contact.givenName.isEmpty ? "User" : contact.givenName
            let lastName = contact.familyName
            
            // Choose a random match reason
            let reasonTypes: [MatchReason] = [
                .sharedContacts, .friendOfFriend, .sameSchool, .contactMatch, .recentlyJoined
            ]
            let randomReason = reasonTypes.randomElement() ?? .contactMatch
            
            // Calculate match score based on reason
            let baseScore = Int.random(in: 30...90)
            let matchScore: Int
            let sharedFriendCount: Int
            
            switch randomReason {
            case .sharedContacts:
                matchScore = baseScore + Int.random(in: 10...30)
                sharedFriendCount = Int.random(in: 1...5)
            case .friendOfFriend:
                matchScore = baseScore + Int.random(in: 5...20)
                sharedFriendCount = Int.random(in: 1...3)
            case .sameSchool:
                matchScore = baseScore + Int.random(in: 1...15)
                sharedFriendCount = 0
            case .contactMatch:
                matchScore = baseScore + Int.random(in: 5...25)
                sharedFriendCount = 0
            case .recentlyJoined:
                matchScore = baseScore
                sharedFriendCount = 0
            }
            
            let suggestion = FriendSuggestion(
                id: UUID().uuidString,
                userId: UUID().uuidString,
                firstName: firstName,
                lastName: lastName,
                username: "\(firstName.lowercased())\(Int.random(in: 100...999))",
                profilePictureURL: nil,
                schoolId: userProfileSystem.currentUser?.schoolId,
                schoolName: userProfileSystem.currentUser?.schoolName,
                flamesCount: Int.random(in: 5...200),
                matchScore: matchScore,
                matchReason: randomReason,
                sharedFriends: nil,
                sharedFriendCount: sharedFriendCount
            )
            
            suggestions.append(suggestion)
        }
        
        // Sort by match score
        suggestions.sort { $0.matchScore > $1.matchScore }
        
        // Update published property
        self.friendSuggestions = suggestions
        
        // Save to defaults
        saveSuggestionsToDefaults()
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        var formatted = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        // Ensure UK numbers start with +44
        if formatted.hasPrefix("0") {
            formatted = "+44" + formatted.dropFirst()
        } else if !formatted.hasPrefix("+") {
            formatted = "+44" + formatted
        }
        
        return formatted
    }
    
    // MARK: - Friend Management
    func addFriend(from suggestion: FriendSuggestion) -> Friend {
        let newFriend = Friend(
            id: UUID().uuidString,
            userId: suggestion.userId,
            firstName: suggestion.firstName,
            lastName: suggestion.lastName,
            username: suggestion.username,
            profilePictureURL: suggestion.profilePictureURL,
            schoolId: suggestion.schoolId,
            schoolName: suggestion.schoolName,
            flamesCount: suggestion.flamesCount ?? 0,
            friendshipDate: Date(),
            isFavorite: false,
            lastInteractionDate: nil,
            polledCount: 0,
            receivedPollCount: 0
        )
        
        friends.append(newFriend)
        
        // Remove from suggestions
        if let index = friendSuggestions.firstIndex(where: { $0.userId == suggestion.userId }) {
            friendSuggestions.remove(at: index)
        }
        
        saveFriendsToDefaults()
        saveSuggestionsToDefaults()
        
        return newFriend
    }
    
    func removeFriend(id: String) {
        friends.removeAll { $0.id == id }
        saveFriendsToDefaults()
    }
    
    func toggleFavorite(friendId: String) {
        if let index = friends.firstIndex(where: { $0.id == friendId }) {
            friends[index].isFavorite.toggle()
            saveFriendsToDefaults()
        }
    }
    
    func recordInteraction(friendId: String) {
        if let index = friends.firstIndex(where: { $0.id == friendId }) {
            friends[index].lastInteractionDate = Date()
            saveFriendsToDefaults()
        }
    }
    
    func incrementPolledCount(friendId: String) {
        if let index = friends.firstIndex(where: { $0.id == friendId }) {
            friends[index].polledCount += 1
            saveFriendsToDefaults()
        }
    }
    
    func incrementReceivedPollCount(friendId: String) {
        if let index = friends.firstIndex(where: { $0.id == friendId }) {
            friends[index].receivedPollCount += 1
            saveFriendsToDefaults()
        }
    }
    
    func getFriendshipStatus(userId: String) -> FriendshipStatus {
        if friends.contains(where: { $0.userId == userId }) {
            return .friend
        } else if friendSuggestions.contains(where: { $0.userId == userId }) {
            return .suggested
        } else {
            return .notConnected
        }
    }
    
    func searchFriends(query: String) -> [Friend] {
        guard !query.isEmpty else { return friends }
        
        let lowercasedQuery = query.lowercased()
        return friends.filter { friend in
            friend.firstName.lowercased().contains(lowercasedQuery) ||
            friend.lastName.lowercased().contains(lowercasedQuery) ||
            friend.username?.lowercased().contains(lowercasedQuery) == true ||
            friend.fullName.lowercased().contains(lowercasedQuery)
        }
    }
    
    // MARK: - Invite Management
    func generateInviteLink(for contact: ContactToInvite) -> URL {
        // In a real app, you would generate a custom invite link with your backend
        // For demo purposes, we'll create a mock URL
        
        let baseUrl = "https://lengleng.app/invite"
        let inviteCode = UUID().uuidString.prefix(8)
        
        // Add referrer info if available
        var urlComponents = URLComponents(string: baseUrl)!
        
        urlComponents.queryItems = [
            URLQueryItem(name: "code", value: String(inviteCode)),
            URLQueryItem(name: "referrer", value: userProfileSystem.currentUser?.id)
        ]
        
        return urlComponents.url!
    }
    
    func sendInvite(to contact: ContactToInvite) -> Bool {
        // Check if user has invites remaining
        guard let useInviteSuccess = userProfileSystem.useInvite(), useInviteSuccess else {
            return false
        }
        
        // In a real app, you would:
        // 1. Generate an invite link with your backend
        // 2. Send an SMS through your backend
        // 3. Track the invite status
        
        return true
    }
    
    // MARK: - Persistence
    private func saveFriendsToDefaults() {
        if let encoded = try? JSONEncoder().encode(friends) {
            userDefaults.set(encoded, forKey: "friends")
        }
    }
    
    private func saveContactsToInviteToDefaults() {
        if let encoded = try? JSONEncoder().encode(contactsToInvite) {
            userDefaults.set(encoded, forKey: "contactsToInvite")
        }
    }
    
    private func saveSuggestionsToDefaults() {
        if let encoded = try? JSONEncoder().encode(friendSuggestions) {
            userDefaults.set(encoded, forKey: "friendSuggestions")
        }
    }
    
    private func loadFriendsFromDefaults() {
        if let data = userDefaults.data(forKey: "friends"),
           let decoded = try? JSONDecoder().decode([Friend].self, from: data) {
            friends = decoded
        }
    }
    
    private func loadSuggestionsFromDefaults() {
        if let data = userDefaults.data(forKey: "friendSuggestions"),
           let decoded = try? JSONDecoder().decode([FriendSuggestion].self, from: data) {
            friendSuggestions = decoded
        }
        
        if let data = userDefaults.data(forKey: "contactsToInvite"),
           let decoded = try? JSONDecoder().decode([ContactToInvite].self, from: data) {
            contactsToInvite = decoded
        }
    }
} 