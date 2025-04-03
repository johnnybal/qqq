import SwiftUI
import FirebaseCore

@main
struct LengLengApp: App {
    @StateObject private var userService = UserService()
    @StateObject private var socialGraphService = SocialGraphSystem()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(userService)
                .environmentObject(socialGraphService)
        }
    }
} 