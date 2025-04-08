import SwiftUI

struct NewComplimentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firestoreService: FirestoreService
    @State private var message = ""
    @State private var isAnonymous = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextEditor(text: $message)
                        .frame(height: 100)
                }
                
                Section {
                    Toggle("Post Anonymously", isOn: $isAnonymous)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Compliment")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Post") { postCompliment() }
                    .disabled(message.isEmpty || isLoading)
            )
        }
    }
    
    private func postCompliment() {
        isLoading = true
        
        Task {
            do {
                let compliment = Compliment(
                    message: message,
                    isAnonymous: isAnonymous,
                    senderId: isAnonymous ? nil : Auth.auth().currentUser?.uid,
                    receiverId: Auth.auth().currentUser?.uid ?? ""
                )
                
                try await firestoreService.createCompliment(compliment)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
} 