import SwiftUI

struct MainContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                QuestionView()
                    .navigationTitle("Questions")
            }
            .tabItem {
                Image(systemName: "questionmark.circle.fill")
                Text("Questions")
            }
            .tag(0)
            
            NavigationView {
                Text("Friends View")
                    .navigationTitle("Friends")
            }
            .tabItem {
                Image(systemName: "person.2.fill")
                Text("Friends")
            }
            .tag(1)
            
            NavigationView {
                Text("Profile View")
                    .navigationTitle("Profile")
            }
            .tabItem {
                Image(systemName: "person.circle.fill")
                Text("Profile")
            }
            .tag(2)
        }
    }
} 