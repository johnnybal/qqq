import SwiftUI
import FirebaseCore

@main
struct LengLengApp: App {
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var firestoreService = FirestoreService.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                ContentView()
                    .environmentObject(authService)
                    .environmentObject(firestoreService)
            } else {
                AuthenticationView()
                    .environmentObject(authService)
                    .environmentObject(firestoreService)
            }
        }
    }
} 