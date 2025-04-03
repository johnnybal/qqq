import SwiftUI
import StoreKit

struct SubscriptionStatusView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showingSubscriptionView = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Subscription Status
            VStack(spacing: 8) {
                Text(subscriptionService.isSubscribed ? "Power Mode Active" : "Free Plan")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if subscriptionService.isSubscribed {
                    Text("You have access to all premium features")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Upgrade to unlock premium features")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // Free Trial Progress
            if !subscriptionService.isSubscribed && subscriptionService.pollsVotedForTrial > 0 {
                VStack(spacing: 12) {
                    Text("Free Trial Progress")
                        .font(.headline)
                    
                    Text("Vote on \(3 - subscriptionService.pollsVotedForTrial) more polls to unlock a free trial!")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: Double(subscriptionService.pollsVotedForTrial), total: 3)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.horizontal)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            
            // Subscription Options
            if !subscriptionService.isSubscribed {
                VStack(spacing: 16) {
                    Text("Subscription Options")
                        .font(.headline)
                    
                    if subscriptionService.isLoading {
                        ProgressView()
                            .padding()
                    } else if !subscriptionService.availableProducts.isEmpty {
                        ForEach(subscriptionService.availableProducts, id: \.id) { product in
                            SubscriptionOptionRow(product: product) {
                                purchaseSubscription(product: product)
                            }
                        }
                    } else {
                        Text("No subscription options available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            
            // Manage Subscription Button
            if subscriptionService.isSubscribed {
                Button(action: {
                    if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Manage Subscription")
                        .fontWeight(.semibold)
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button(action: { showingSubscriptionView = true }) {
                    Text("View All Subscription Options")
                        .fontWeight(.semibold)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding()
        .sheet(isPresented: $showingSubscriptionView) {
            SubscriptionView()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            Task {
                await subscriptionService.checkSubscriptionStatus()
            }
        }
    }
    
    private func purchaseSubscription(product: Product) {
        Task {
            do {
                try await subscriptionService.purchaseSubscription(product: product)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

struct SubscriptionOptionRow: View {
    let product: Product
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                    
                    if let unit = product.subscription?.subscriptionPeriod.unit,
                       let value = product.subscription?.subscriptionPeriod.value {
                        Text("\(value) \(unit == .month ? "month" : "year")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SubscriptionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionStatusView()
    }
} 