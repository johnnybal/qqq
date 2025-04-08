import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentStep = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                ProgressView(value: Double(currentStep), total: Double(viewModel.totalSteps))
                    .padding()
                
                TabView(selection: $currentStep) {
                    // Step 1: Welcome
                    WelcomeStepView()
                        .tag(0)
                    
                    // Step 2: Profile Picture
                    ProfilePictureStepView(selectedImage: $viewModel.profileImage)
                        .tag(1)
                    
                    // Step 3: Basic Info
                    BasicInfoStepView(
                        displayName: $viewModel.displayName,
                        username: $viewModel.username
                    )
                        .tag(2)
                    
                    // Step 4: Demographics
                    DemographicsStepView(
                        gender: $viewModel.gender,
                        age: $viewModel.age
                    )
                        .tag(3)
                    
                    // Step 5: School Info
                    SchoolInfoStepView(
                        schoolName: $viewModel.schoolName,
                        grade: $viewModel.grade
                    )
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if currentStep < viewModel.totalSteps - 1 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .disabled(!viewModel.canProceedToNextStep(at: currentStep))
                    } else {
                        Button("Get Started") {
                            Task {
                                await viewModel.completeOnboarding()
                            }
                        }
                        .disabled(!viewModel.canCompleteOnboarding)
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - View Models
class OnboardingViewModel: ObservableObject {
    @Published var profileImage: UIImage?
    @Published var displayName = ""
    @Published var username = ""
    @Published var gender = ""
    @Published var age = 0
    @Published var schoolName = ""
    @Published var grade = ""
    
    let totalSteps = 5
    
    var canCompleteOnboarding: Bool {
        !displayName.isEmpty &&
        !username.isEmpty &&
        !gender.isEmpty &&
        age > 0
    }
    
    func canProceedToNextStep(at step: Int) -> Bool {
        switch step {
        case 0: return true // Welcome step
        case 1: return profileImage != nil
        case 2: return !displayName.isEmpty && !username.isEmpty
        case 3: return !gender.isEmpty && age > 0
        case 4: return true // School info is optional
        default: return false
        }
    }
    
    func completeOnboarding() async {
        // TODO: Implement onboarding completion
        // 1. Upload profile image
        // 2. Create user profile
        // 3. Update authentication state
    }
}

// MARK: - Step Views
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Welcome to LengLeng!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Let's set up your profile to get started")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct ProfilePictureStepView: View {
    @Binding var selectedImage: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add a Profile Picture")
                .font(.title2)
                .fontWeight(.bold)
            
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                    )
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 150, height: 150)
                    .foregroundColor(.gray)
            }
            
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text(selectedImage == nil ? "Choose Photo" : "Change Photo")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .onChange(of: pickerItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
}

struct BasicInfoStepView: View {
    @Binding var displayName: String
    @Binding var username: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tell us about yourself")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 15) {
                TextField("Display Name", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
            }
            .padding()
        }
    }
}

struct DemographicsStepView: View {
    @Binding var gender: String
    @Binding var age: Int
    
    let genders = ["Male", "Female", "Non-binary", "Prefer not to say"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Basic Information")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 15) {
                Picker("Gender", selection: $gender) {
                    ForEach(genders, id: \.self) { gender in
                        Text(gender).tag(gender)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                Stepper("Age: \(age)", value: $age, in: 13...100)
            }
            .padding()
        }
    }
}

struct SchoolInfoStepView: View {
    @Binding var schoolName: String
    @Binding var grade: String
    
    let grades = ["9th", "10th", "11th", "12th", "College", "Other"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("School Information")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 15) {
                TextField("School Name", text: $schoolName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("Grade", selection: $grade) {
                    ForEach(grades, id: \.self) { grade in
                        Text(grade).tag(grade)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding()
        }
    }
} 