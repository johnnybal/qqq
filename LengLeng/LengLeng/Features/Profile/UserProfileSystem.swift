//
//  UserProfileSystem.swift
//  LengLeng
//
//  Created: April 3, 2025
//

import Foundation
import SwiftUI
import Contacts
import CoreLocation
import FirebaseAuth
import FirebaseFirestore

class UserProfileSystem: ObservableObject {
    // MARK: - Properties
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isPhoneVerified: Bool = false
    @Published var isProfileComplete: Bool = false
    @Published var authenticationError: String?
    @Published var schoolOptions: [School] = []
    @Published var selectedSchool: School?
    
    // Location manager for school proximity detection
    private let locationManager = CLLocationManager()
    private let userDefaults = UserDefaults.standard
    private let db = Firestore.firestore()
    
    // MARK: - Models
    struct User: Codable, Identifiable {
        let id: String
        var phoneNumber: String
        var firstName: String
        var lastName: String
        var username: String?
        var profilePictureURL: URL?
        var schoolId: String?
        var schoolName: String?
        var joinDate: Date
        var isPremium: Bool
        var premiumExpiryDate: Date?
        var flamesCount: Int
        var gemsCount: Int
        var invitesRemaining: Int
        var totalPolls: Int
        var totalVotesReceived: Int
        
        // Computed property for full name
        var fullName: String {
            return "\(firstName) \(lastName)"
        }
        
        // Computed property for display name (username if available, otherwise first name)
        var displayName: String {
            return username ?? firstName
        }
        
        // Initialize with default values
        init(id: String = UUID().uuidString,
             phoneNumber: String = "",
             firstName: String = "",
             lastName: String = "",
             username: String? = nil,
             profilePictureURL: URL? = nil,
             schoolId: String? = nil,
             schoolName: String? = nil,
             joinDate: Date = Date(),
             isPremium: Bool = false,
             premiumExpiryDate: Date? = nil,
             flamesCount: Int = 0,
             gemsCount: Int = 0,
             invitesRemaining: Int = 10,
             totalPolls: Int = 0,
             totalVotesReceived: Int = 0) {
            self.id = id
            self.phoneNumber = phoneNumber
            self.firstName = firstName
            self.lastName = lastName
            self.username = username
            self.profilePictureURL = profilePictureURL
            self.schoolId = schoolId
            self.schoolName = schoolName
            self.joinDate = joinDate
            self.isPremium = isPremium
            self.premiumExpiryDate = premiumExpiryDate
            self.flamesCount = flamesCount
            self.gemsCount = gemsCount
            self.invitesRemaining = invitesRemaining
            self.totalPolls = totalPolls
            self.totalVotesReceived = totalVotesReceived
        }
    }
    
    struct School: Codable, Identifiable {
        let id: String
        let name: String
        let address: String
        let city: String
        let postcode: String
        let latitude: Double
        let longitude: Double
        let studentCount: Int?
        let isActive: Bool
        
        // Computed property for full address
        var fullAddress: String {
            return "\(address), \(city), \(postcode)"
        }
    }
    
    // MARK: - Initialization
    init() {
        loadUserFromDefaults()
        setupLocationManager()
    }
    
    // MARK: - Location Manager Setup
    private func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Phone Authentication
    func sendVerificationCode(phoneNumber: String, completion: @escaping (Bool, String?) -> Void) {
        // Format phone number to ensure it includes country code
        let formattedNumber = formatPhoneNumber(phoneNumber)
        
        // Use Firebase Phone Authentication
        PhoneAuthProvider.provider().verifyPhoneNumber(formattedNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
                return
            }
            
            if let verificationID = verificationID {
                // Store verification ID
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                
                // Store phone number temporarily
                DispatchQueue.main.async {
                    self.currentUser = User(phoneNumber: formattedNumber)
                    self.saveUserToDefaults()
                    completion(true, nil)
                }
            }
        }
    }
    
    func verifyCode(code: String, completion: @escaping (Bool, String?) -> Void) {
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            completion(false, "Missing verification ID")
            return
        }
        
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
                return
            }
            
            if let authResult = authResult {
                DispatchQueue.main.async {
                    self?.isPhoneVerified = true
                    self?.currentUser?.id = authResult.user.uid
                    self?.saveUserToDefaults()
                    completion(true, nil)
                }
            }
        }
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        var formatted = number.replacingOccurrences(of: " ", with: "")
        
        // Ensure UK numbers start with +44
        if formatted.hasPrefix("0") {
            formatted = "+44" + formatted.dropFirst()
        } else if !formatted.hasPrefix("+") {
            formatted = "+44" + formatted
        }
        
        return formatted
    }
    
    // MARK: - Profile Setup
    func createProfile(firstName: String, lastName: String, username: String? = nil, completion: @escaping (Bool, String?) -> Void) {
        guard isPhoneVerified, var user = currentUser else {
            completion(false, "Phone number not verified")
            return
        }
        
        // Update user object
        user.firstName = firstName
        user.lastName = lastName
        user.username = username
        
        // Save to Firestore
        do {
            let data = try JSONEncoder().encode(user)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            db.collection("users").document(user.id).setData(dict) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(false, error.localizedDescription)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.currentUser = user
                    self.saveUserToDefaults()
                    completion(true, nil)
                }
            }
        } catch {
            DispatchQueue.main.async {
                completion(false, error.localizedDescription)
            }
        }
    }
    
    func updateProfilePicture(imageData: Data, completion: @escaping (Bool, URL?, String?) -> Void) {
        guard var user = currentUser else {
            completion(false, nil, "User not found")
            return
        }
        
        // In a real app, this would upload the image to Firebase Storage
        // For now, we'll use a local file URL
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(user.id)-profile.jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            user.profilePictureURL = fileURL
            currentUser = user
            saveUserToDefaults()
            completion(true, fileURL, nil)
        } catch {
            completion(false, nil, "Failed to save profile picture: \(error.localizedDescription)")
        }
    }
    
    // MARK: - School Selection
    func fetchNearbySchools(completion: @escaping ([School]?, String?) -> Void) {
        guard let location = locationManager.location else {
            fetchAllSchools(completion: completion)
            return
        }
        
        // In a real app, this would fetch schools from Firestore
        // For development, we'll provide a sample list of schools
        
        let sampleSchools = [
            School(id: "school1", name: "Oakwood Secondary School", address: "1 Oak Street", city: "London", postcode: "SW1A 1AA", latitude: 51.5074, longitude: -0.1278, studentCount: 850, isActive: true),
            School(id: "school2", name: "Riverside Academy", address: "25 River Road", city: "London", postcode: "SW1A 2BB", latitude: 51.5080, longitude: -0.1290, studentCount: 1200, isActive: true),
            School(id: "school3", name: "Hillside High School", address: "10 Hill Avenue", city: "London", postcode: "SW1A 3CC", latitude: 51.5060, longitude: -0.1260, studentCount: 950, isActive: true)
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.schoolOptions = sampleSchools
            completion(sampleSchools, nil)
        }
    }
    
    func fetchAllSchools(completion: @escaping ([School]?, String?) -> Void) {
        // In a real app, this would fetch all available schools from Firestore
        // For development, we'll provide a sample list
        
        let sampleSchools = [
            School(id: "school1", name: "Oakwood Secondary School", address: "1 Oak Street", city: "London", postcode: "SW1A 1AA", latitude: 51.5074, longitude: -0.1278, studentCount: 850, isActive: true),
            School(id: "school2", name: "Riverside Academy", address: "25 River Road", city: "London", postcode: "SW1A 2BB", latitude: 51.5080, longitude: -0.1290, studentCount: 1200, isActive: true),
            School(id: "school3", name: "Hillside High School", address: "10 Hill Avenue", city: "London", postcode: "SW1A 3CC", latitude: 51.5060, longitude: -0.1260, studentCount: 950, isActive: true),
            School(id: "school4", name: "Meadowview College", address: "5 Meadow Lane", city: "Manchester", postcode: "M1 1DE", latitude: 53.4808, longitude: -2.2426, studentCount: 1050, isActive: true),
            School(id: "school5", name: "Central Grammar School", address: "15 Central Road", city: "Birmingham", postcode: "B1 1FG", latitude: 52.4862, longitude: -1.8904, studentCount: 1100, isActive: true)
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.schoolOptions = sampleSchools
            completion(sampleSchools, nil)
        }
    }
    
    func selectSchool(schoolId: String, completion: @escaping (Bool, String?) -> Void) {
        guard var user = currentUser else {
            completion(false, "User not found")
            return
        }
        
        if let school = schoolOptions.first(where: { $0.id == schoolId }) {
            user.schoolId = school.id
            user.schoolName = school.name
            currentUser = user
            selectedSchool = school
            saveUserToDefaults()
            
            // Update in Firestore
            db.collection("users").document(user.id).updateData([
                "schoolId": school.id,
                "schoolName": school.name
            ]) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(false, error.localizedDescription)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.isProfileComplete = true
                    self.isAuthenticated = true
                    completion(true, nil)
                }
            }
        } else {
            completion(false, "School not found")
        }
    }
    
    // MARK: - User Stats Management
    func addFlames(count: Int) {
        guard var user = currentUser else { return }
        user.flamesCount += count
        currentUser = user
        saveUserToDefaults()
        
        // Update in Firestore
        db.collection("users").document(user.id).updateData([
            "flamesCount": user.flamesCount
        ])
    }
    
    func addGems(count: Int) {
        guard var user = currentUser else { return }
        user.gemsCount += count
        currentUser = user
        saveUserToDefaults()
        
        // Update in Firestore
        db.collection("users").document(user.id).updateData([
            "gemsCount": user.gemsCount
        ])
    }
    
    func useInvite() -> Bool {
        guard var user = currentUser, user.invitesRemaining > 0 else { return false }
        user.invitesRemaining -= 1
        currentUser = user
        saveUserToDefaults()
        
        // Update in Firestore
        db.collection("users").document(user.id).updateData([
            "invitesRemaining": user.invitesRemaining
        ])
        
        return true
    }
    
    func addInvites(count: Int) {
        guard var user = currentUser else { return }
        user.invitesRemaining += count
        currentUser = user
        saveUserToDefaults()
        
        // Update in Firestore
        db.collection("users").document(user.id).updateData([
            "invitesRemaining": user.invitesRemaining
        ])
    }
    
    func incrementTotalVotesReceived() {
        guard var user = currentUser else { return }
        user.totalVotesReceived += 1
        currentUser = user
        saveUserToDefaults()
        
        // Update in Firestore
        db.collection("users").document(user.id).updateData([
            "totalVotesReceived": user.totalVotesReceived
        ])
    }
    
    func incrementTotalPolls() {
        guard var user = currentUser else { return }
        user.totalPolls += 1
        currentUser = user
        saveUserToDefaults()
        
        // Update in Firestore
        db.collection("users").document(user.id).updateData([
            "totalPolls": user.totalPolls
        ])
    }
    
    // MARK: - Premium Management
    func activatePremium(durationInDays: Int = 30) {
        guard var user = currentUser else { return }
        user.isPremium = true
        user.premiumExpiryDate = Calendar.current.date(byAdding: .day, value: durationInDays, to: Date())
        currentUser = user
        saveUserToDefaults()
        
        // Update in Firestore
        db.collection("users").document(user.id).updateData([
            "isPremium": true,
            "premiumExpiryDate": user.premiumExpiryDate as Any
        ])
    }
    
    func checkPremiumStatus() {
        guard var user = currentUser,
              user.isPremium,
              let expiryDate = user.premiumExpiryDate else { return }
        
        // Check if premium has expired
        if Date() > expiryDate {
            user.isPremium = false
            user.premiumExpiryDate = nil
            currentUser = user
            saveUserToDefaults()
            
            // Update in Firestore
            db.collection("users").document(user.id).updateData([
                "isPremium": false,
                "premiumExpiryDate": FieldValue.delete()
            ])
        }
    }
    
    // MARK: - Contact Access
    func requestContactAccess(completion: @escaping (Bool) -> Void) {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    // MARK: - Authentication Management
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
        
        currentUser = nil
        isAuthenticated = false
        isPhoneVerified = false
        isProfileComplete = false
        userDefaults.removeObject(forKey: "currentUser")
    }
    
    // Check if user has an active session
    func checkSession() {
        if let user = Auth.auth().currentUser {
            // User is signed in with Firebase
            if currentUser == nil {
                // Load user data from Firestore
                db.collection("users").document(user.uid).getDocument { [weak self] document, error in
                    if let document = document, document.exists,
                       let data = document.data(),
                       let jsonData = try? JSONSerialization.data(withJSONObject: data),
                       let user = try? JSONDecoder().decode(User.self, from: jsonData) {
                        DispatchQueue.main.async {
                            self?.currentUser = user
                            self?.isPhoneVerified = true
                            self?.isProfileComplete = (user.schoolId != nil)
                            self?.isAuthenticated = true
                            self?.checkPremiumStatus()
                        }
                    }
                }
            } else {
                // User data already loaded
                isPhoneVerified = true
                isProfileComplete = (currentUser?.schoolId != nil)
                isAuthenticated = true
                checkPremiumStatus()
            }
        } else {
            // No user signed in
            currentUser = nil
            isAuthenticated = false
            isPhoneVerified = false
            isProfileComplete = false
        }
    }
    
    // MARK: - Persistence
    private func saveUserToDefaults() {
        guard let user = currentUser, let encoded = try? JSONEncoder().encode(user) else { return }
        userDefaults.set(encoded, forKey: "currentUser")
    }
    
    private func loadUserFromDefaults() {
        if let userData = userDefaults.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
            isPhoneVerified = true
            isProfileComplete = (user.schoolId != nil)
            checkSession()
        }
    }
}

// MARK: - SwiftUI Views
extension UserProfileSystem {
    
    // Profile View
    func ProfileView() -> some View {
        Group {
            if let user = currentUser {
                VStack(alignment: .center, spacing: 16) {
                    // Profile Picture
                    if let profileURL = user.profilePictureURL,
                       let imageData = try? Data(contentsOf: profileURL),
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.blue, lineWidth: 3))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                    
                    // User Name
                    Text(user.fullName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let username = user.username {
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // School
                    if let schoolName = user.schoolName {
                        HStack {
                            Image(systemName: "building.2")
                            Text(schoolName)
                        }
                        .font(.subheadline)
                        .padding(.top, 4)
                    }
                    
                    // Premium Status
                    if user.isPremium {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Power Mode Active")
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    // Stats Section
                    VStack(spacing: 12) {
                        HStack(spacing: 40) {
                            VStack {
                                Text("\(user.flamesCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Flames")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(user.gemsCount)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Gems")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(user.invitesRemaining)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Invites")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 8)
                        
                        Divider()
                        
                        HStack(spacing: 40) {
                            VStack {
                                Text("\(user.totalVotesReceived)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Votes Received")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(user.totalPolls)")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Polls Participated")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            } else {
                Text("Profile not available")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Profile Edit Button View
    func ProfileEditButton() -> some View {
        Button(action: {
            // This would typically navigate to profile edit screen
            // Using your app's navigation system
        }) {
            Image(systemName: "pencil")
                .padding(10)
                .background(Circle().fill(Color.blue))
                .foregroundColor(.white)
        }
    }
    
    // Mini Profile View (for use in lists or compact displays)
    func MiniProfileView() -> some View {
        Group {
            if let user = currentUser {
                HStack {
                    // Profile Picture
                    if let profileURL = user.profilePictureURL,
                       let imageData = try? Data(contentsOf: profileURL),
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(user.displayName)
                            .font(.headline)
                        
                        if user.isPremium {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                Text("Power Mode")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text("🔥 \(user.flamesCount)")
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            } else {
                Text("User not available")
                    .foregroundColor(.secondary)
            }
        }
    }
} 