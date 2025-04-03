import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("pushNotificationsEnabled") private var pushNotificationsEnabled = true
    @AppStorage("emailNotificationsEnabled") private var emailNotificationsEnabled = false
    @AppStorage("showProfileToOthers") private var showProfileToOthers = true
    @AppStorage("showVoteHistory") private var showVoteHistory = false
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("language") private var language = "English"
    
    private let languages = ["English", "Spanish", "French", "German", "Chinese"]
    
    var body: some View {
        NavigationView {
            List {
                Section("Notifications") {
                    Toggle("Push Notifications", isOn: $pushNotificationsEnabled)
                    Toggle("Email Notifications", isOn: $emailNotificationsEnabled)
                }
                
                Section("Privacy") {
                    Toggle("Show Profile to Others", isOn: $showProfileToOthers)
                    Toggle("Show Vote History", isOn: $showVoteHistory)
                }
                
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $darkModeEnabled)
                    Picker("Language", selection: $language) {
                        ForEach(languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                }
                
                Section("Account") {
                    NavigationLink("Change Password") {
                        ChangePasswordView()
                    }
                    NavigationLink("Privacy Policy") {
                        PrivacyPolicyView()
                    }
                    NavigationLink("Terms of Service") {
                        TermsOfServiceView()
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Rate the App", destination: URL(string: "https://apps.apple.com/app/lengleng")!)
                    Link("Send Feedback", destination: URL(string: "mailto:feedback@lengleng.com")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Current Password")) {
                SecureField("Enter current password", text: $currentPassword)
            }
            
            Section(header: Text("New Password")) {
                SecureField("Enter new password", text: $newPassword)
                SecureField("Confirm new password", text: $confirmPassword)
            }
            
            Section {
                Button("Change Password") {
                    changePassword()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Change Password")
        .alert("Password Change", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func changePassword() {
        // Validate passwords
        guard !currentPassword.isEmpty else {
            alertMessage = "Please enter your current password"
            showingAlert = true
            return
        }
        
        guard !newPassword.isEmpty else {
            alertMessage = "Please enter a new password"
            showingAlert = true
            return
        }
        
        guard newPassword == confirmPassword else {
            alertMessage = "New passwords do not match"
            showingAlert = true
            return
        }
        
        // TODO: Implement password change logic with Firebase
        alertMessage = "Password changed successfully"
        showingAlert = true
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .padding(.bottom)
                
                Text("Last updated: March 15, 2024")
                    .foregroundColor(.secondary)
                
                Group {
                    Text("1. Information We Collect")
                        .font(.headline)
                    Text("We collect information that you provide directly to us, including your name, email address, phone number, and profile information.")
                    
                    Text("2. How We Use Your Information")
                        .font(.headline)
                    Text("We use the information we collect to provide, maintain, and improve our services, to communicate with you, and to personalize your experience.")
                    
                    Text("3. Information Sharing")
                        .font(.headline)
                    Text("We do not share your personal information with third parties except as described in this privacy policy.")
                }
                .padding(.vertical, 4)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title)
                    .padding(.bottom)
                
                Text("Last updated: March 15, 2024")
                    .foregroundColor(.secondary)
                
                Group {
                    Text("1. Acceptance of Terms")
                        .font(.headline)
                    Text("By accessing and using LengLeng, you accept and agree to be bound by the terms and provision of this agreement.")
                    
                    Text("2. Use License")
                        .font(.headline)
                    Text("Permission is granted to temporarily download one copy of the app for personal, non-commercial transitory viewing only.")
                    
                    Text("3. User Conduct")
                        .font(.headline)
                    Text("You agree not to use the service to violate any laws, harass others, or interfere with the proper functioning of the service.")
                }
                .padding(.vertical, 4)
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
    }
} 