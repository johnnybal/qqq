import SwiftUI

struct ProfileView: View {
    @StateObject private var profileSystem = UserProfileSystem()
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // Use the ProfileView from UserProfileSystem
                    profileSystem.ProfileView()
                        .padding(.bottom)
                    
                    // Account Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                    .foregroundColor(.blue)
                                Text("Settings")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            profileSystem.logout()
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                    .foregroundColor(.red)
                                Text("Sign Out")
                                Spacer()
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingEditProfile = true
                    }) {
                        Image(systemName: "pencil")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(profileSystem: profileSystem)
            }
            .onAppear {
                profileSystem.checkSession()
            }
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var profileSystem: UserProfileSystem
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var username: String = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Picture")) {
                    HStack {
                        Spacer()
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                        } else if let user = profileSystem.currentUser,
                                  let profileURL = user.profilePictureURL,
                                  let imageData = try? Data(contentsOf: profileURL),
                                  let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    Button("Change Photo") {
                        showingImagePicker = true
                    }
                }
                
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Username (optional)", text: $username)
                }
                
                Section {
                    Button("Save Changes") {
                        saveProfile()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .onAppear {
                if let user = profileSystem.currentUser {
                    firstName = user.firstName
                    lastName = user.lastName
                    username = user.username ?? ""
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    private func saveProfile() {
        profileSystem.createProfile(firstName: firstName, lastName: lastName, username: username.isEmpty ? nil : username) { success, error in
            if success {
                if let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.7) {
                    profileSystem.updateProfilePicture(imageData: imageData) { _, _, _ in
                        dismiss()
                    }
                } else {
                    dismiss()
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Notifications") {
                    Toggle("Push Notifications", isOn: .constant(true))
                    Toggle("Email Notifications", isOn: .constant(false))
                }
                
                Section("Privacy") {
                    Toggle("Show Profile to Others", isOn: .constant(true))
                    Toggle("Show Vote History", isOn: .constant(false))
                }
                
                Section("About") {
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Text("Version 1.0.0")
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
} 