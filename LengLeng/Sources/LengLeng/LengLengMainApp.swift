import SwiftUI
import FirebaseCore

@main
struct LengLeng: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
    }
} 