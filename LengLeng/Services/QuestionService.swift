import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class QuestionService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var questions: [Question] = []
    @Published var userResponses: [String: String] = [:] // [questionId: selectedOption]
    
    func fetchQuestions(for userId: String, userAge: Int, userGender: String) async throws {
        // Fetch questions that the user hasn't answered yet
        let responseSnapshot = try await db.collection("userResponses")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let answeredQuestionIds = responseSnapshot.documents.compactMap { document in
            document.data()["questionId"] as? String
        }
        
        // Build query for active questions
        var query = db.collection("questions")
            .whereField("status", isEqualTo: "active")
            .whereField("id", notIn: answeredQuestionIds)
        
        // Add age filter
        query = query.whereField("ageAppropriate.min", isLessThanOrEqualTo: userAge)
            .whereField("ageAppropriate.max", isGreaterThanOrEqualTo: userAge)
        
        // Add gender filter
        if userGender != "all" {
            query = query.whereField("genderTarget", in: ["all", userGender])
        }
        
        // Add schedule filter
        let now = Date()
        query = query.whereField("schedule.startDate", isLessThanOrEqualTo: now)
            .whereField("schedule.endDate", isGreaterThanOrEqualTo: now)
        
        // Execute query
        let snapshot = try await query
            .order(by: "schedule.timeOfDay", descending: false)
            .getDocuments()
        
        questions = snapshot.documents.compactMap { document in
            try? document.data(as: Question.self)
        }
        
        // Store user responses for reference
        userResponses = responseSnapshot.documents.reduce(into: [String: String]()) { result, document in
            if let questionId = document.data()["questionId"] as? String,
               let response = document.data()["response"] as? String {
                result[questionId] = response
            }
        }
    }
    
    func submitResponse(questionId: String, userId: String, response: String) async throws {
        // Update question responses and engagement metrics
        try await db.collection("questions").document(questionId).updateData([
            "responses.\(userId)": response,
            "engagement.responses": FieldValue.increment(Int64(1)),
            "lastModified": Date()
        ])
        
        // Update user responses
        try await db.collection("userResponses").document("\(userId)_\(questionId)").setData([
            "userId": userId,
            "questionId": questionId,
            "response": response,
            "timestamp": Date()
        ])
        
        // Update local state
        userResponses[questionId] = response
    }
    
    func getQuestionStats(questionId: String) async throws -> [String: Int] {
        let snapshot = try await db.collection("questions").document(questionId).getDocument()
        guard let question = try? snapshot.data(as: Question.self) else {
            return [:]
        }
        
        return question.responses.reduce(into: [String: Int]()) { result, response in
            result[response.value, default: 0] += 1
        }
    }
    
    func incrementImpression(questionId: String) async throws {
        try await db.collection("questions").document(questionId).updateData([
            "engagement.impressions": FieldValue.increment(Int64(1)),
            "lastModified": Date()
        ])
    }
} 