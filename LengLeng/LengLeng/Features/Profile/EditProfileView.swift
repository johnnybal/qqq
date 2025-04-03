import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var profileSystem: UserProfileSystem
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
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
                    
                    PhotosPicker(selection: $selectedItem,
                               matching: .images) {
                        Label("Change Photo", systemImage: "photo")
                    }
                }
                
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                    TextField("Username (optional)", text: $username)
                        .textContentType(.username)
                    TextField("Bio (optional)", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button(action: saveProfile) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .onAppear {
                loadUserData()
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .alert("Profile Update", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("successfully") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadUserData() {
        if let user = profileSystem.currentUser {
            firstName = user.firstName
            lastName = user.lastName
            username = user.username ?? ""
            bio = user.bio ?? ""
        }
    }
    
    private func saveProfile() {
        guard !firstName.isEmpty else {
            alertMessage = "Please enter your first name"
            showingAlert = true
            return
        }
        
        guard !lastName.isEmpty else {
            alertMessage = "Please enter your last name"
            showingAlert = true
            return
        }
        
        isLoading = true
        
        profileSystem.createProfile(
            firstName: firstName,
            lastName: lastName,
            username: username.isEmpty ? nil : username,
            bio: bio.isEmpty ? nil : bio
        ) { success, error in
            if success {
                if let image = selectedImage,
                   let imageData = image.jpegData(compressionQuality: 0.7) {
                    profileSystem.updateProfilePicture(imageData: imageData) { success, _, error in
                        isLoading = false
                        if success {
                            alertMessage = "Profile updated successfully"
                        } else {
                            alertMessage = error?.localizedDescription ?? "Failed to update profile picture"
                        }
                        showingAlert = true
                    }
                } else {
                    isLoading = false
                    alertMessage = "Profile updated successfully"
                    showingAlert = true
                }
            } else {
                isLoading = false
                alertMessage = error?.localizedDescription ?? "Failed to update profile"
                showingAlert = true
            }
        }
    }
} 