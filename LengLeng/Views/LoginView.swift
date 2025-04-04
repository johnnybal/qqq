import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @EnvironmentObject var userService: UserService
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to LengLeng")
                .font(.largeTitle)
                .padding(.bottom, 40)
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Button(action: {
                isLoading = true
                errorMessage = nil
                
                userService.signIn(email: email, password: password) { result in
                    isLoading = false
                    switch result {
                    case .success:
                        // Navigation will be handled by the parent view
                        break
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Login")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            
            Button("Don't have an account? Sign up") {
                // TODO: Navigate to sign up
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
} 