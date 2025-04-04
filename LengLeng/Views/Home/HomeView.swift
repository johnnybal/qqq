import SwiftUI

struct HomeView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeContentView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            PollsView()
                .tabItem {
                    Label("Polls", systemImage: "chart.bar")
                }
                .tag(1)
            
            SocialView()
                .tabItem {
                    Label("Social", systemImage: "person.2")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(3)
        }
    }
}

struct HomeContentView: View {
    @State private var recentActivity: [Activity] = []
    @EnvironmentObject var userService: UserService
    
    var body: some View {
        NavigationView {
            List {
                if recentActivity.isEmpty {
                    Text("No recent activity")
                        .foregroundColor(.gray)
                } else {
                    ForEach(recentActivity) { activity in
                        ActivityRow(activity: activity)
                    }
                }
            }
            .navigationTitle("Recent Activity")
            .refreshable {
                // TODO: Refresh activity
            }
        }
    }
}

struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack {
            Image(systemName: activity.icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(activity.title)
                    .font(.headline)
                Text(activity.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .relative)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let timestamp: Date
}

#Preview {
    HomeView()
        .environmentObject(UserService())
        .environmentObject(SocialGraphSystem())
} 