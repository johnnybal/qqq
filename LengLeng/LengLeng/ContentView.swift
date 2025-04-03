//
//  ContentView.swift
//  LengLeng
//
//  Created by John Balestrieri on 4/3/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var notificationsSystem: NotificationsSystem
    @State private var selectedTab = 0
    @StateObject private var userProfileSystem = UserProfileSystem()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PollsView()
                .tabItem {
                    Label("Polls", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            SocialView(userProfileSystem: userProfileSystem)
                .tabItem {
                    Label("Social", systemImage: "person.2.fill")
                }
                .tag(1)
            
            ProfileView(profileSystem: userProfileSystem)
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(2)
        }
        .onAppear {
            notificationsSystem.requestPermission()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(NotificationsSystem())
    }
}
