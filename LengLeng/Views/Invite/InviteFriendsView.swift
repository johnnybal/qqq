import SwiftUI
import ContactsUI

struct InviteFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var invitationService: InvitationService
    
    @State private var selectedContacts: Set<ContactToInvite> = []
    @State private var showingContactPicker = false
    @State private var customMessage: String = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    // Selected Contacts List
                    if !selectedContacts.isEmpty {
                        List {
                            ForEach(Array(selectedContacts), id: \.id) { contact in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(contact.name)
                                            .font(.headline)
                                        Text(contact.phoneNumber)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: { selectedContacts.remove(contact) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .frame(height: min(CGFloat(selectedContacts.count * 60), 300))
                    }
                    
                    // Custom Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Message (Optional)")
                            .font(.headline)
                        
                        TextEditor(text: $customMessage)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    // Add Contacts Button
                    Button(action: { showingContactPicker = true }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Add Contacts")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Send Invites Button
                    if !selectedContacts.isEmpty {
                        Button(action: sendInvites) {
                            if isSending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Send \(selectedContacts.count) Invite\(selectedContacts.count > 1 ? "s" : "")")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(isSending)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                
                if invitationService.isLoading {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .navigationTitle("Invite Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingContactPicker) {
                ContactPicker(selectedContacts: $selectedContacts)
            }
            .alert("Error", isPresented: $showingError, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
            .onChange(of: invitationService.error) { error in
                if let error = error {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func sendInvites() {
        guard !selectedContacts.isEmpty else { return }
        
        isSending = true
        errorMessage = nil
        
        Task {
            do {
                for contact in selectedContacts {
                    let success = try await invitationService.sendInvite(
                        to: contact,
                        message: customMessage.isEmpty ? nil : customMessage
                    )
                    
                    if !success {
                        throw InvitationError.sendFailed
                    }
                }
                
                await MainActor.run {
                    isSending = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

struct ContactPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedContacts: Set<ContactToInvite>
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPicker
        
        init(_ parent: ContactPicker) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            let newContacts = contacts.map { contact in
                ContactToInvite(
                    id: UUID().uuidString,
                    name: [contact.givenName, contact.familyName]
                        .filter { !$0.isEmpty }
                        .joined(separator: " "),
                    phoneNumber: contact.phoneNumbers.first?.value.stringValue ?? "",
                    school: nil
                )
            }
            
            parent.selectedContacts.formUnion(newContacts)
            parent.dismiss()
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.dismiss()
        }
    }
}

#Preview {
    InviteFriendsView(invitationService: InvitationService(
        userService: UserService(),
        socialGraphService: SocialGraphSystem()
    ))
} 