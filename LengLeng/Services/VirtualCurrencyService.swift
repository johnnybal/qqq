import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class VirtualCurrencyService: ObservableObject {
    static let shared = VirtualCurrencyService()
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var currentBalance: VirtualCurrency?
    @Published var recentTransactions: [CurrencyTransaction] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private init() {
        setupCurrencyListener()
    }
    
    private func setupCurrencyListener() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("virtual_currency")
            .document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error
                    return
                }
                
                guard let data = snapshot?.data(),
                      let currency = try? VirtualCurrency(
                        id: snapshot?.documentID ?? "",
                        userId: userId,
                        flames: data["flames"] as? Int ?? 0,
                        gems: data["gems"] as? Int ?? 0,
                        lastUpdated: (data["lastUpdated"] as? Timestamp)?.dateValue() ?? Date()
                    ) else {
                    return
                }
                
                self.currentBalance = currency
            }
    }
    
    // MARK: - Currency Operations
    
    func awardFlames(amount: Int, type: CurrencyTransactionType, metadata: [String: String] = [:]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "VirtualCurrencyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let transaction = CurrencyTransaction(
            id: UUID().uuidString,
            userId: userId,
            type: type,
            amount: amount,
            currencyType: .flames,
            timestamp: Date(),
            metadata: metadata
        )
        
        try await db.runTransaction { transaction, errorPointer in
            let currencyRef = self.db.collection("virtual_currency").document(userId)
            let transactionRef = self.db.collection("currency_transactions").document(transaction.id)
            
            // Update currency balance
            transaction.updateData([
                "flames": FieldValue.increment(Int64(amount)),
                "lastUpdated": Timestamp()
            ], forDocument: currencyRef)
            
            // Record transaction
            try transaction.setData(from: transaction, forDocument: transactionRef)
            
            return nil
        }
    }
    
    func awardGems(amount: Int, type: CurrencyTransactionType, metadata: [String: String] = [:]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "VirtualCurrencyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let transaction = CurrencyTransaction(
            id: UUID().uuidString,
            userId: userId,
            type: type,
            amount: amount,
            currencyType: .gems,
            timestamp: Date(),
            metadata: metadata
        )
        
        try await db.runTransaction { transaction, errorPointer in
            let currencyRef = self.db.collection("virtual_currency").document(userId)
            let transactionRef = self.db.collection("currency_transactions").document(transaction.id)
            
            // Update currency balance
            transaction.updateData([
                "gems": FieldValue.increment(Int64(amount)),
                "lastUpdated": Timestamp()
            ], forDocument: currencyRef)
            
            // Record transaction
            try transaction.setData(from: transaction, forDocument: transactionRef)
            
            return nil
        }
    }
    
    func spendGems(amount: Int, type: CurrencyTransactionType, metadata: [String: String] = [:]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "VirtualCurrencyService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        guard let balance = currentBalance, balance.gems >= amount else {
            throw NSError(domain: "VirtualCurrencyService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Insufficient gems"])
        }
        
        let transaction = CurrencyTransaction(
            id: UUID().uuidString,
            userId: userId,
            type: type,
            amount: -amount,
            currencyType: .gems,
            timestamp: Date(),
            metadata: metadata
        )
        
        try await db.runTransaction { transaction, errorPointer in
            let currencyRef = self.db.collection("virtual_currency").document(userId)
            let transactionRef = self.db.collection("currency_transactions").document(transaction.id)
            
            // Update currency balance
            transaction.updateData([
                "gems": FieldValue.increment(Int64(-amount)),
                "lastUpdated": Timestamp()
            ], forDocument: currencyRef)
            
            // Record transaction
            try transaction.setData(from: transaction, forDocument: transactionRef)
            
            return nil
        }
    }
    
    // MARK: - Transaction History
    
    func loadRecentTransactions(limit: Int = 10) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let snapshot = try await db.collection("currency_transactions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        let transactions = try snapshot.documents.compactMap { document -> CurrencyTransaction? in
            try document.data(as: CurrencyTransaction.self)
        }
        
        DispatchQueue.main.async {
            self.recentTransactions = transactions
        }
    }
    
    // MARK: - Helper Methods
    
    func initializeCurrency(for userId: String) async throws {
        let currency = VirtualCurrency(
            id: userId,
            userId: userId,
            flames: 0,
            gems: 0,
            lastUpdated: Date()
        )
        
        try await db.collection("virtual_currency")
            .document(userId)
            .setData(from: currency)
    }
    
    func checkAndAwardDailyBonus() async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let lastUpdated = currentBalance?.lastUpdated else { return }
        
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastUpdated) {
            // Award daily bonus
            try await awardGems(
                amount: CurrencyRewards.premiumDailyBonus,
                type: .dailyBonus,
                metadata: ["reason": "daily_bonus"]
            )
        }
    }
} 