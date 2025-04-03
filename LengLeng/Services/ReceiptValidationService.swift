import Foundation
import StoreKit

enum ReceiptValidationError: Error {
    case invalidReceipt
    case serverError
    case networkError
    case unknown
}

class ReceiptValidationService {
    static let shared = ReceiptValidationService()
    
    // Apple's production URL for receipt validation
    private let productionURL = URL(string: "https://buy.itunes.apple.com/verifyReceipt")!
    
    // Apple's sandbox URL for receipt validation (for testing)
    private let sandboxURL = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
    
    private init() {}
    
    // MARK: - Receipt Validation
    
    func validateReceipt(transaction: Transaction) async throws -> Bool {
        // Get the receipt data
        guard let receiptData = try? await getReceiptData() else {
            throw ReceiptValidationError.invalidReceipt
        }
        
        // Create the request payload
        let requestBody: [String: Any] = [
            "receipt-data": receiptData.base64EncodedString(),
            "password": "YOUR_APP_SHARED_SECRET", // Replace with your app's shared secret from App Store Connect
            "exclude-old-transactions": false
        ]
        
        // Convert the request body to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw ReceiptValidationError.invalidReceipt
        }
        
        // Create the request
        var request = URLRequest(url: productionURL)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            // Send the request to Apple's servers
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ReceiptValidationError.networkError
            }
            
            // Check if the response is successful
            guard httpResponse.statusCode == 200 else {
                // If the status code is 21007, it means we're using the production URL but the receipt is from the sandbox
                if httpResponse.statusCode == 21007 {
                    // Retry with the sandbox URL
                    return try await validateReceiptWithSandbox(transaction: transaction)
                }
                
                throw ReceiptValidationError.serverError
            }
            
            // Parse the response
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? Int else {
                throw ReceiptValidationError.unknown
            }
            
            // Check if the receipt is valid
            guard status == 0 else {
                throw ReceiptValidationError.invalidReceipt
            }
            
            // Verify the transaction
            return try await verifyTransaction(transaction, in: json)
        } catch {
            throw ReceiptValidationError.networkError
        }
    }
    
    private func validateReceiptWithSandbox(transaction: Transaction) async throws -> Bool {
        // Get the receipt data
        guard let receiptData = try? await getReceiptData() else {
            throw ReceiptValidationError.invalidReceipt
        }
        
        // Create the request payload
        let requestBody: [String: Any] = [
            "receipt-data": receiptData.base64EncodedString(),
            "password": "YOUR_APP_SHARED_SECRET", // Replace with your app's shared secret from App Store Connect
            "exclude-old-transactions": false
        ]
        
        // Convert the request body to JSON data
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw ReceiptValidationError.invalidReceipt
        }
        
        // Create the request
        var request = URLRequest(url: sandboxURL)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            // Send the request to Apple's servers
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ReceiptValidationError.networkError
            }
            
            // Check if the response is successful
            guard httpResponse.statusCode == 200 else {
                throw ReceiptValidationError.serverError
            }
            
            // Parse the response
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let status = json["status"] as? Int else {
                throw ReceiptValidationError.unknown
            }
            
            // Check if the receipt is valid
            guard status == 0 else {
                throw ReceiptValidationError.invalidReceipt
            }
            
            // Verify the transaction
            return try await verifyTransaction(transaction, in: json)
        } catch {
            throw ReceiptValidationError.networkError
        }
    }
    
    private func getReceiptData() async throws -> Data {
        // Get the receipt URL
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            throw ReceiptValidationError.invalidReceipt
        }
        
        // Check if the receipt exists
        guard FileManager.default.fileExists(atPath: receiptURL.path) else {
            throw ReceiptValidationError.invalidReceipt
        }
        
        // Read the receipt data
        return try Data(contentsOf: receiptURL)
    }
    
    private func verifyTransaction(_ transaction: Transaction, in json: [String: Any]) async throws -> Bool {
        // Get the latest receipt info
        guard let latestReceiptInfo = json["latest_receipt_info"] as? [[String: Any]] else {
            return false
        }
        
        // Find the transaction in the latest receipt info
        for receipt in latestReceiptInfo {
            guard let transactionId = receipt["transaction_id"] as? String,
                  let productId = receipt["product_id"] as? String,
                  let expiresDateMs = receipt["expires_date_ms"] as? String,
                  let expiresDate = Double(expiresDateMs) / 1000.0 else {
                continue
            }
            
            // Check if this is the transaction we're looking for
            if transactionId == transaction.id && productId == transaction.productID {
                // Check if the subscription is still active
                let expirationDate = Date(timeIntervalSince1970: expiresDate)
                return expirationDate > Date()
            }
        }
        
        return false
    }
} 