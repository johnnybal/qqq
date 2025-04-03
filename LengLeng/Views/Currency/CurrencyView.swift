import SwiftUI

struct CurrencyView: View {
    @StateObject private var currencyService = VirtualCurrencyService.shared
    @State private var showingTransactionDetails = false
    @State private var selectedTransaction: CurrencyTransaction?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Currency Balance Cards
                    HStack(spacing: 15) {
                        CurrencyCard(
                            title: "Flames",
                            amount: currencyService.currentBalance?.formattedFlames ?? "0 🔥",
                            color: .orange
                        )
                        
                        CurrencyCard(
                            title: "Gems",
                            amount: currencyService.currentBalance?.formattedGems ?? "0 💎",
                            color: .blue
                        )
                    }
                    .padding(.horizontal)
                    
                    // Recent Transactions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if currencyService.recentTransactions.isEmpty {
                            Text("No recent transactions")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(currencyService.recentTransactions) { transaction in
                                TransactionRow(transaction: transaction)
                                    .onTapGesture {
                                        selectedTransaction = transaction
                                        showingTransactionDetails = true
                                    }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Your Currency")
            .refreshable {
                try? await currencyService.loadRecentTransactions()
            }
            .sheet(isPresented: $showingTransactionDetails) {
                if let transaction = selectedTransaction {
                    TransactionDetailView(transaction: transaction)
                }
            }
            .task {
                try? await currencyService.loadRecentTransactions()
            }
        }
    }
}

struct CurrencyCard: View {
    let title: String
    let amount: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(amount)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct TransactionRow: View {
    let transaction: CurrencyTransaction
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(transaction.formattedAmount)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.amount >= 0 ? .green : .red)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .padding(.horizontal)
    }
}

struct TransactionDetailView: View {
    let transaction: CurrencyTransaction
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    DetailRow(title: "Type", value: transaction.type.rawValue.capitalized)
                    DetailRow(title: "Amount", value: transaction.formattedAmount)
                    DetailRow(title: "Date", value: transaction.timestamp.formatted())
                }
                
                if !transaction.metadata.isEmpty {
                    Section("Details") {
                        ForEach(transaction.metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                            DetailRow(title: key.capitalized, value: value)
                        }
                    }
                }
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    CurrencyView()
} 