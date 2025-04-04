import SwiftUI
import ContactsUI

struct InviteFriendsView: View {
    @ObservedObject var invitationService: InvitationService
    @Environment(\.dismiss) private var dismiss
    @State private var showingContactPicker = false
    @State private var selectedContact: CNContact?
    @State private var message = "Hey! Join me on LengLeng, it's a great way to stay connected!"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Message Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invitation Message")
                            .font(.headline)
                        
                        TextEditor(text: $message)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // Contact Selection
                    Button(action: { showingContactPicker = true }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text(selectedContact?.givenName ?? "Select Contact")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Send Invitation Button
                    Button(action: sendInvitation) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Invitation")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedContact != nil ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(selectedContact == nil)
                }
                .padding()
            }
            .navigationTitle("Invite Friends")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .sheet(isPresented: $showingContactPicker) {
                ContactPickerViewController(contact: $selectedContact)
            }
        }
    }
    
    private func sendInvitation() {
        guard let contact = selectedContact else { return }
        invitationService.sendInvitation(to: "\(contact.givenName) \(contact.familyName)", message: message)
        dismiss()
    }
}

struct ContactPickerViewController: UIViewControllerRepresentable {
    @Binding var contact: CNContact?
    
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
        var parent: ContactPickerViewController
        
        init(_ parent: ContactPickerViewController) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            parent.contact = contact
        }
    }
}

#Preview {
    InviteFriendsView(invitationService: InvitationService(userService: UserService(), socialGraphService: SocialGraphSystem()))
} 