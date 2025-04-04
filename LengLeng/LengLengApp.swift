import SwiftUI
import FirebaseCore

@main
struct LengLengApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var userService = UserService()
    @StateObject private var socialGraphService = SocialGraphSystem()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(userService)
                .environmentObject(socialGraphService)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
} 