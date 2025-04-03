//
//  LengLengApp.swift
//  LengLeng
//
//  Created by John Balestrieri on 4/3/25.
//

import SwiftUI
import FirebaseCore

@main
struct LengLengApp: App {
    @StateObject private var notificationsSystem = NotificationsSystem()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notificationsSystem)
        }
    }
}
