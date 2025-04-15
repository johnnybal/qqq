import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                Text("Questions")
                    .navigationTitle("Questions")
            }
            .tabItem {
                Image(systemName: "questionmark.circle")
                Text("Questions")
            }
            .tag(0)
            
            NavigationView {
                Text("Friends")
                    .navigationTitle("Friends")
            }
            .tabItem {
                Image(systemName: "person.2")
                Text("Friends")
            }
            .tag(1)
            
            NavigationView {
                Text("Profile")
                    .navigationTitle("Profile")
            }
            .tabItem {
                Image(systemName: "person.circle")
                Text("Profile")
            }
            .tag(2)
        }
    }
} 