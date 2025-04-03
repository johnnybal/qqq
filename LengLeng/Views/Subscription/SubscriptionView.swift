import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @StateObject private var subscriptionService = SubscriptionService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedProduct: Product?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isStartingFreeTrial = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Power Mode")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Unlock the full potential of LengLeng")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(icon: "infinity", title: "Unlimited Invites", description: "Send as many invites as you want")
                        FeatureRow(icon: "chart.bar.fill", title: "Advanced Analytics", description: "Get detailed insights about your invites")
                        FeatureRow(icon: "paintbrush.fill", title: "Custom Themes", description: "Personalize your app experience")
                        FeatureRow(icon: "star.fill", title: "Priority Support", description: "Get help when you need it")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Subscription Options
                    if subscriptionService.isLoading {
                        ProgressView()
                            .padding()
                    } else if !subscriptionService.availableProducts.isEmpty {
                        VStack(spacing: 16) {
                            ForEach(subscriptionService.availableProducts, id: \.id) { product in
                                SubscriptionOptionButton(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    action: { selectedProduct = product }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Free Trial Offer
                    if subscriptionService.freeTrialEligible {
                        VStack(spacing: 12) {
                            Text("🎉 Free Trial Available!")
                                .font(.headline)
                            
                            Text("You've voted on \(subscriptionService.pollsVotedForTrial) polls. Get a free month of Power Mode!")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                            
                            Button(action: startFreeTrial) {
                                if isStartingFreeTrial {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Start Free Trial")
                                        .fontWeight(.semibold)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(isStartingFreeTrial)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                    } else if subscriptionService.pollsVotedForTrial > 0 {
                        VStack(spacing: 8) {
                            Text("Vote on \(3 - subscriptionService.pollsVotedForTrial) more polls to unlock a free trial!")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: Double(subscriptionService.pollsVotedForTrial), total: 3)
                                .progressViewStyle(LinearProgressViewStyle())
                                .padding(.horizontal)
                        }
                        .padding()
                    }
                    
                    // Purchase Button
                    if let selectedProduct = selectedProduct {
                        Button(action: { purchaseSubscription(product: selectedProduct) }) {
                            if subscriptionService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Subscribe for \(selectedProduct.displayPrice)")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(subscriptionService.isLoading)
                        .padding(.horizontal)
                    }
                    
                    // Terms and Privacy
                    VStack(spacing: 4) {
                        Text("By subscribing, you agree to our")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Link("Terms of Service", destination: URL(string: "https://lengleng.app/terms")!)
                            Text("and")
                                .foregroundColor(.secondary)
                            Link("Privacy Policy", destination: URL(string: "https://lengleng.app/privacy")!)
                        }
                        .font(.caption)
                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .navigationBarTitle("Subscription", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { dismiss() })
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func purchaseSubscription(product: Product) {
        Task {
            do {
                try await subscriptionService.purchaseSubscription(product: product)
                dismiss()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func startFreeTrial() {
        isStartingFreeTrial = true
        
        Task {
            do {
                try await subscriptionService.startFreeTrial()
                await MainActor.run {
                    isStartingFreeTrial = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isStartingFreeTrial = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
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
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SubscriptionOptionButton: View {
    let product: Product
    let isSelected: Bool
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
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
    }
} 