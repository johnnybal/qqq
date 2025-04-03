import Foundation
import StoreKit
import FirebaseFirestore
import FirebaseAuth

enum SubscriptionTier: String, Codable {
    case free
    case powerMode
}

enum SubscriptionError: LocalizedError {
    case purchaseFailed
    case verificationFailed
    case noActiveSubscription
    case freeTrialNotAvailable
    case unknown
    case productNotFound
    case receiptValidationFailed
    
    var errorDescription: String? {
        switch self {
        case .purchaseFailed:
            return "Failed to complete the purchase"
        case .verificationFailed:
            return "Failed to verify your subscription"
        case .noActiveSubscription:
            return "You don't have an active subscription"
        case .freeTrialNotAvailable:
            return "Free trial is not available at this time"
        case .unknown:
            return "An unknown error occurred"
        case .productNotFound:
            return "Subscription product not found"
        case .receiptValidationFailed:
            return "Failed to validate your purchase with Apple"
        }
    }
}

class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()
    
    private let db = Firestore.firestore()
    private var products: [Product] = []
    private var updateListenerTask: Task<Void, Error>?
    private var transactionListenerTask: Task<Void, Error>?
    
    @Published var currentTier: SubscriptionTier = .free
    @Published var isSubscribed = false
    @Published var isLoading = false
    @Published var error: SubscriptionError?
    @Published var availableProducts: [Product] = []
    @Published var freeTrialEligible = false
    @Published var pollsVotedForTrial = 0
    
    private init() {
        setupStoreKit()
        loadSubscriptionStatus()
        checkFreeTrialEligibility()
    }
    
    deinit {
        updateListenerTask?.cancel()
        transactionListenerTask?.cancel()
    }
    
    // MARK: - StoreKit Setup
    
    private func setupStoreKit() {
        // Start listening for transactions
        transactionListenerTask = listenForTransactions()
        
        // Load products
        Task {
            await loadProducts()
        }
        
        // Check for any pending transactions
        Task {
            await checkForPendingTransactions()
        }
    }
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                await self.handleTransactionResult(result)
            }
        }
    }
    
    private func checkForPendingTransactions() async {
        for await result in Transaction.currentEntitlements {
            await handleTransactionResult(result)
        }
    }
    
    private func loadProducts() async {
        do {
            let productIdentifiers = ["com.lengleng.powermode.monthly", "com.lengleng.powermode.yearly"]
            products = try await Product.products(for: productIdentifiers)
            
            await MainActor.run {
                availableProducts = products
            }
        } catch {
            print("Failed to load products: \(error)")
            await MainActor.run {
                self.error = .productNotFound
            }
        }
    }
    
    // MARK: - Subscription Management
    
    func loadSubscriptionStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Error loading subscription status: \(error)")
                    return
                }
                
                if let data = snapshot?.data(),
                   let tierString = data["subscriptionTier"] as? String,
                   let tier = SubscriptionTier(rawValue: tierString) {
                    self?.currentTier = tier
                    self?.isSubscribed = tier == .powerMode
                }
            }
        }
    }
    
    func purchaseSubscription(product: Product) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                await handleTransactionResult(verification)
            case .userCancelled:
                throw SubscriptionError.purchaseFailed
            case .pending:
                throw SubscriptionError.purchaseFailed
            @unknown default:
                throw SubscriptionError.unknown
            }
        } catch {
            throw SubscriptionError.purchaseFailed
        }
    }
    
    private func handleTransactionResult(_ result: VerificationResult<Transaction>) async {
        guard let transaction = try? result.payloadValue else {
            return
        }
        
        // Verify the transaction with Apple's servers
        do {
            let isValid = try await ReceiptValidationService.shared.validateReceipt(transaction: transaction)
            
            if isValid {
                // Update the user's subscription status
                await updateSubscriptionStatus(for: transaction)
                
                // Finish the transaction
                await transaction.finish()
            } else {
                throw SubscriptionError.verificationFailed
            }
        } catch {
            print("Failed to verify transaction: \(error)")
            await MainActor.run {
                self.error = .receiptValidationFailed
            }
        }
    }
    
    private func verifyReceipt(_ transaction: Transaction) async throws {
        // Verify the receipt with Apple's servers
        let isValid = try await ReceiptValidationService.shared.validateReceipt(transaction: transaction)
        
        if !isValid {
            throw SubscriptionError.verificationFailed
        }
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Store the transaction ID in Firestore for server-side verification
        try await db.collection("users").document(userId).collection("transactions").document(transaction.id).setData([
            "transactionId": transaction.id,
            "productId": transaction.productID,
            "purchaseDate": Timestamp(date: transaction.purchaseDate),
            "expirationDate": transaction.expirationDate.map { Timestamp(date: $0) },
            "verified": true
        ])
    }
    
    private func updateSubscriptionStatus(for transaction: Transaction) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            // Determine subscription tier based on product ID
            let tier: SubscriptionTier = transaction.productID.contains("powermode") ? .powerMode : .free
            
            try await db.collection("users").document(userId).updateData([
                "subscriptionTier": tier.rawValue,
                "subscriptionExpiryDate": Timestamp(date: transaction.expirationDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60)),
                "subscriptionProductId": transaction.productID,
                "lastTransactionId": transaction.id
            ])
            
            await MainActor.run {
                currentTier = tier
                isSubscribed = tier == .powerMode
            }
        } catch {
            print("Failed to update subscription status: \(error)")
        }
    }
    
    // MARK: - Free Trial Management
    
    func checkFreeTrialEligibility() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let data = snapshot?.data(),
               let hasUsedTrial = data["hasUsedFreeTrial"] as? Bool,
               let pollsVoted = data["pollsVotedForTrial"] as? Int {
                
                DispatchQueue.main.async {
                    self?.freeTrialEligible = !hasUsedTrial && pollsVoted >= 3
                    self?.pollsVotedForTrial = pollsVoted
                }
            }
        }
    }
    
    func startFreeTrial() async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        guard freeTrialEligible else {
            throw SubscriptionError.freeTrialNotAvailable
        }
        
        do {
            // Update user's subscription status
            try await db.collection("users").document(userId).updateData([
                "subscriptionTier": SubscriptionTier.powerMode.rawValue,
                "subscriptionExpiryDate": Timestamp(date: Date().addingTimeInterval(30 * 24 * 60 * 60)), // 30 days
                "hasUsedFreeTrial": true,
                "freeTrialStartedAt": Timestamp(date: Date()),
                "isFreeTrial": true
            ])
            
            await MainActor.run {
                currentTier = .powerMode
                isSubscribed = true
                freeTrialEligible = false
            }
        } catch {
            throw SubscriptionError.unknown
        }
    }
    
    func incrementPollsVotedForTrial() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await db.collection("users").document(userId).updateData([
                "pollsVotedForTrial": FieldValue.increment(Int64(1))
            ])
            
            await MainActor.run {
                pollsVotedForTrial += 1
                if pollsVotedForTrial >= 3 {
                    freeTrialEligible = true
                }
            }
        } catch {
            print("Failed to increment polls voted: \(error)")
        }
    }
    
    // MARK: - Premium Feature Access
    
    func isPremiumFeatureAvailable(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .unlimitedInvites:
            return isSubscribed
        case .advancedAnalytics:
            return isSubscribed
        case .customThemes:
            return isSubscribed
        case .prioritySupport:
            return isSubscribed
        }
    }
    
    // MARK: - Subscription Status Check
    
    func checkSubscriptionStatus() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("users").document(userId).getDocument()
            
            if let data = snapshot.data(),
               let tierString = data["subscriptionTier"] as? String,
               let tier = SubscriptionTier(rawValue: tierString),
               let expiryDate = data["subscriptionExpiryDate"] as? Timestamp {
                
                // Check if subscription has expired
                if expiryDate.dateValue() < Date() {
                    // Subscription has expired, update status
                    try await db.collection("users").document(userId).updateData([
                        "subscriptionTier": SubscriptionTier.free.rawValue
                    ])
                    
                    await MainActor.run {
                        currentTier = .free
                        isSubscribed = false
                    }
                } else {
                    await MainActor.run {
                        currentTier = tier
                        isSubscribed = tier == .powerMode
                    }
                }
            }
        } catch {
            print("Failed to check subscription status: \(error)")
        }
    }
}

// MARK: - Premium Features

enum PremiumFeature {
    case unlimitedInvites
    case advancedAnalytics
    case customThemes
    case prioritySupport
} 