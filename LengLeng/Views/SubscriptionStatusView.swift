import SwiftUI
import StoreKit

struct SubscriptionStatusView: View {
    @StateObject private var subscriptionService = SubscriptionService()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Subscription Status
                    VStack(spacing: 12) {
                        Image(systemName: subscriptionService.isSubscribed ? "star.fill" : "star")
                            .font(.system(size: 60))
                            .foregroundColor(subscriptionService.isSubscribed ? .yellow : .gray)
                        
                        Text(subscriptionService.isSubscribed ? "Power Mode Active" : "Upgrade to Power Mode")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(subscriptionService.isSubscribed ? "Your subscription is active" : "Unlock all features")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Features List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                        
                        FeatureRow(icon: "person.2.fill", title: "Unlimited Connections", description: "Connect with as many friends as you want")
                        FeatureRow(icon: "chart.bar.fill", title: "Advanced Analytics", description: "Get detailed insights about your network")
                        FeatureRow(icon: "bell.fill", title: "Priority Notifications", description: "Never miss important updates")
                        FeatureRow(icon: "shield.fill", title: "Ad-Free Experience", description: "Enjoy the app without advertisements")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                .padding()
            }
            .navigationTitle("Subscription")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SubscriptionStatusView()
} 