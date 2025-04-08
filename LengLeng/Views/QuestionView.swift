import SwiftUI

struct QuestionView: View {
    @StateObject private var questionService = QuestionService()
    @State private var currentQuestionIndex = 0
    @State private var showingStats = false
    @State private var selectedOption: String?
    @State private var stats: [String: Int] = [:]
    @State private var showingCategory = false
    
    let user: UserProfile
    
    var body: some View {
        VStack {
            if questionService.questions.isEmpty {
                ProgressView("Loading questions...")
            } else if currentQuestionIndex < questionService.questions.count {
                let question = questionService.questions[currentQuestionIndex]
                
                VStack(spacing: 20) {
                    // Question Card
                    VStack(spacing: 16) {
                        // Category Badge
                        HStack {
                            Text(question.category.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(12)
                            Spacer()
                        }
                        
                        // Question Text with Emoji
                        HStack(alignment: .center, spacing: 8) {
                            Text(question.emoji)
                                .font(.system(size: 40))
                            Text(question.text)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        
                        // Schedule Info
                        if question.schedule.frequency != .daily {
                            Text("Special Question")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    
                    // Options
                    VStack(spacing: 12) {
                        ForEach(question.options, id: \.self) { option in
                            Button(action: {
                                selectedOption = option
                                Task {
                                    try? await questionService.submitResponse(
                                        questionId: question.id ?? "",
                                        userId: user.id ?? "",
                                        response: option
                                    )
                                    try? await loadStats(for: question)
                                    showingStats = true
                                }
                            }) {
                                Text(option)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedOption == option ? Color.blue : Color.gray)
                                    .cornerRadius(10)
                            }
                            .disabled(selectedOption != nil)
                        }
                    }
                    .padding()
                }
                .padding()
                
                // Stats View
                if showingStats {
                    VStack(spacing: 16) {
                        Text("Results")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        ForEach(question.options, id: \.self) { option in
                            HStack {
                                Text(option)
                                Spacer()
                                Text("\(stats[option] ?? 0)")
                            }
                            .padding(.horizontal)
                        }
                        
                        // Engagement Info
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Responses: \(question.engagement.responses)")
                                    .font(.caption)
                                Text("Response Rate: \(Int(question.engagement.responseRate * 100))%")
                                    .font(.caption)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        
                        Button("Next Question") {
                            currentQuestionIndex += 1
                            selectedOption = nil
                            showingStats = false
                            stats = [:]
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                }
            } else {
                VStack {
                    Text("No more questions!")
                        .font(.title2)
                    Text("Check back later for new questions")
                        .foregroundColor(.gray)
                }
            }
        }
        .task {
            try? await questionService.fetchQuestions(
                for: user.id ?? "",
                userAge: calculateAge(from: user.createdAt),
                userGender: user.gender ?? "all"
            )
        }
    }
    
    private func loadStats(for question: Question) async throws {
        stats = try await questionService.getQuestionStats(questionId: question.id ?? "")
    }
    
    private func calculateAge(from date: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: date, to: Date())
        return ageComponents.year ?? 0
    }
} 