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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            PollsView()
                .tabItem {
                    Label("Polls", systemImage: "list.bullet")
                }
                .tag(0)
            
            NotificationsView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
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
