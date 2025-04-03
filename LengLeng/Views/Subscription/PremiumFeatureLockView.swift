import SwiftUI

struct PremiumFeatureLockView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showingSubscriptionView = false
    
    let feature: PremiumFeature
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { showingSubscriptionView = true }) {
                Text("Upgrade to Power Mode")
                    .fontWeight(.semibold)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingSubscriptionView) {
            SubscriptionView()
        }
    }
}

struct PremiumFeatureModifier: ViewModifier {
    let feature: PremiumFeature
    let title: String
    let description: String
    
    @StateObject private var subscriptionService = SubscriptionService.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(subscriptionService.isPremiumFeatureAvailable(feature) ? 1 : 0.3)
                .disabled(!subscriptionService.isPremiumFeatureAvailable(feature))
            
            if !subscriptionService.isPremiumFeatureAvailable(feature) {
                PremiumFeatureLockView(
                    feature: feature,
                    title: title,
                    description: description
                )
            }
        }
    }
}

extension View {
    func premiumFeature(
        _ feature: PremiumFeature,
        title: String,
        description: String
    ) -> some View {
        modifier(PremiumFeatureModifier(
            feature: feature,
            title: title,
            description: description
        ))
    }
}

struct PremiumFeatureLockView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("This is a premium feature")
                .premiumFeature(
                    .unlimitedInvites,
                    title: "Unlimited Invites",
                    description: "Upgrade to Power Mode to send unlimited invites to your friends."
                )
                .padding()
            
            Button("Send Invite") {
                // Action
            }
            .premiumFeature(
                .unlimitedInvites,
                title: "Unlimited Invites",
                description: "Upgrade to Power Mode to send unlimited invites to your friends."
            )
            .padding()
        }
        .previewLayout(.sizeThatFits)
    }
} 