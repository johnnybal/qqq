import Foundation
import FirebaseFirestore
import FirebaseAuth

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Authentication
    func signInWithPhone(phoneNumber: String, completion: @escaping (Result<String, Error>) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let verificationID = verificationID {
                completion(.success(verificationID))
            }
        }
    }
    
    func verifyCode(_ code: String, verificationID: String, completion: @escaping (Result<AuthDataResult, Error>) -> Void) {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let authResult = authResult {
                completion(.success(authResult))
            }
        }
    }
    
    // MARK: - Polls
    func createPoll(_ poll: Poll, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let data = try JSONEncoder().encode(poll)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            db.collection("polls").addDocument(data: dict) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(poll.id))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchPolls(completion: @escaping (Result<[Poll], Error>) -> Void) {
        db.collection("polls")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let polls = documents.compactMap { document -> Poll? in
                    do {
                        let data = try JSONSerialization.data(withJSONObject: document.data())
                        return try JSONDecoder().decode(Poll.self, from: data)
                    } catch {
                        print("Error decoding poll: \(error)")
                        return nil
                    }
                }
                
                completion(.success(polls))
            }
    }
} 