import SwiftUI

struct ReportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firestoreService: FirestoreService
    let contentId: String
    let contentType: String
    @State private var selectedReason = ""
    @State private var customReason = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let reasons = [
        "Inappropriate Content",
        "Harassment",
        "Spam",
        "Hate Speech",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Select Reason") {
                    ForEach(reasons, id: \.self) { reason in
                        Button(action: {
                            selectedReason = reason
                        }) {
                            HStack {
                                Text(reason)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                if selectedReason == "Other" {
                    Section("Custom Reason") {
                        TextEditor(text: $customReason)
                            .frame(height: 100)
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Report Content")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Submit") { submitReport() }
                    .disabled(selectedReason.isEmpty || (selectedReason == "Other" && customReason.isEmpty) || isLoading)
            )
        }
    }
    
    private func submitReport() {
        isLoading = true
        
        Task {
            do {
                let report = ContentReport(
                    reporterId: Auth.auth().currentUser?.uid ?? "",
                    contentId: contentId,
                    contentType: contentType,
                    reason: selectedReason == "Other" ? customReason : selectedReason,
                    timestamp: Date()
                )
                
                try await firestoreService.reportContent(report)
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