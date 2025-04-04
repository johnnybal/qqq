import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

// MARK: - Models
struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let displayName: String
    let username: String
    let phoneNumber: String
    let school: School
    let accountStatus: String
    let registrationDate: Date
    let lastActive: Date
    let flagHistory: [FlagHistory]
    let supportInteractions: [SupportInteraction]
}

struct School: Codable {
    let id: String
    let name: String
}

struct FlagHistory: Codable {
    let reason: String
    let date: Date
    let resolution: String
}

struct SupportInteraction: Codable {
    let ticketId: String
    let date: Date
    let type: String
    let status: String
    let notes: String
}

// MARK: - View Models
class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    
    func fetchUsers() {
        isLoading = true
        db.collection("users")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.error = error
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No documents found"])
                    return
                }
                
                self.users = documents.compactMap { document in
                    try? document.data(as: User.self)
                }
            }
    }
}

// MARK: - UI Components
struct UserCard: View {
    let user: User
    
    @State private var showActionModal = false
    @State private var showFlagHistory = false
    @State private var showSupportHistory = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(user.displayName)
                    .font(.headline)
                Spacer()
                Text(user.accountStatus)
                    .font(.subheadline)
                    .foregroundColor(statusColor)
            }
            
            Text(user.username)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(user.school.name)
                .font(.subheadline)
            
            HStack {
                Image(systemName: "phone")
                Text(user.phoneNumber)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "calendar")
                Text("Joined: \(formattedDate(user.registrationDate))")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            HStack {
                Button(action: { showActionModal = true }) {
                    Text("Actions")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                if !user.flagHistory.isEmpty {
                    Button(action: { showFlagHistory = true }) {
                        Text("\(user.flagHistory.count) flags")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                if !user.supportInteractions.isEmpty {
                    Button(action: { showSupportHistory = true }) {
                        Text("\(user.supportInteractions.count) support tickets")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .sheet(isPresented: $showActionModal) {
            UserActionModal(user: user, onDismiss: { showActionModal = false })
        }
        .sheet(isPresented: $showFlagHistory) {
            FlagHistoryModal(flags: user.flagHistory, onDismiss: { showFlagHistory = false })
        }
        .sheet(isPresented: $showSupportHistory) {
            SupportHistoryModal(interactions: user.supportInteractions, onDismiss: { showSupportHistory = false })
        }
    }
    
    private var statusColor: Color {
        switch user.accountStatus {
        case "active": return .green
        case "suspended": return .red
        case "deleted": return .gray
        default: return .secondary
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct UserListView: View {
    @StateObject private var viewModel = UserViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.users) { user in
                            UserCard(user: user)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.fetchUsers()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
        switch status {
        case "active": return .green
        case "suspended": return .red
        case "deleted": return .gray
        default: return .secondary
        }
    }
}

// MARK: - Modal Components
struct ModalContainer<Content: View>: View {
    let title: String
    let content: Content
    let onDismiss: () -> Void
    let actionButton: (() -> Void)?
    let actionButtonTitle: String?
    
    init(
        title: String,
        onDismiss: @escaping () -> Void,
        actionButton: (() -> Void)? = nil,
        actionButtonTitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.onDismiss = onDismiss
        self.actionButton = actionButton
        self.actionButtonTitle = actionButtonTitle
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Content
            content
                .padding()
            
            // Footer
            if let actionButton = actionButton, let actionButtonTitle = actionButtonTitle {
                HStack {
                    Button("Cancel", action: onDismiss)
                        .buttonStyle(SecondaryButtonStyle())
                    
                    Button(actionButtonTitle, action: actionButton)
                        .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(.systemGray5))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

// MARK: - User Action Modals
struct UserActionModal: View {
    let user: User
    let onDismiss: () -> Void
    @State private var selectedAction: UserAction?
    @State private var showConfirmation = false
    
    enum UserAction: String, CaseIterable {
        case suspend = "Suspend User"
        case delete = "Delete User"
        case viewFlags = "View Flags"
        case viewSupport = "View Support History"
    }
    
    var body: some View {
        ModalContainer(
            title: "User Actions",
            onDismiss: onDismiss
        ) {
            VStack(spacing: 16) {
                ForEach(UserAction.allCases, id: \.rawValue) { action in
                    Button(action: {
                        selectedAction = action
                        showConfirmation = true
                    }) {
                        HStack {
                            Text(action.rawValue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .sheet(isPresented: $showConfirmation) {
            if let action = selectedAction {
                ConfirmationModal(
                    title: "Confirm Action",
                    message: confirmationMessage(for: action),
                    onConfirm: {
                        // Handle action
                        onDismiss()
                    },
                    onCancel: {
                        showConfirmation = false
                    }
                )
            }
        }
    }
    
    private func confirmationMessage(for action: UserAction) -> String {
        switch action {
        case .suspend:
            return "Are you sure you want to suspend \(user.displayName)?"
        case .delete:
            return "Are you sure you want to delete \(user.displayName)? This action cannot be undone."
        case .viewFlags:
            return "View flag history for \(user.displayName)?"
        case .viewSupport:
            return "View support history for \(user.displayName)?"
        }
    }
}

struct ConfirmationModal: View {
    let title: String
    let message: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ModalContainer(
            title: title,
            onDismiss: onCancel,
            actionButton: onConfirm,
            actionButtonTitle: "Confirm"
        ) {
            Text(message)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

struct FlagHistoryModal: View {
    let flags: [FlagHistory]
    let onDismiss: () -> Void
    
    var body: some View {
        ModalContainer(
            title: "Flag History",
            onDismiss: onDismiss
        ) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(flags, id: \.date) { flag in
                        FlagHistoryCard(flag: flag)
                    }
                }
            }
        }
    }
}

struct FlagHistoryCard: View {
    let flag: FlagHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(flag.reason)
                .font(.headline)
            
            HStack {
                Image(systemName: "calendar")
                Text(formattedDate(flag.date))
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            if !flag.resolution.isEmpty {
                Text("Resolution: \(flag.resolution)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SupportHistoryModal: View {
    let interactions: [SupportInteraction]
    let onDismiss: () -> Void
    
    var body: some View {
        ModalContainer(
            title: "Support History",
            onDismiss: onDismiss
        ) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(interactions, id: \.ticketId) { interaction in
                        SupportInteractionCard(interaction: interaction)
                    }
                }
            }
        }
    }
}

struct SupportInteractionCard: View {
    let interaction: SupportInteraction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Ticket #\(interaction.ticketId)")
                    .font(.headline)
                Spacer()
                StatusBadge(status: interaction.status)
            }
            
            Text(interaction.type)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "calendar")
                Text(formattedDate(interaction.date))
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            if !interaction.notes.isEmpty {
                Text(interaction.notes)
                    .font(.subheadline)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Profile Components
struct ProfileHeader: View {
    let user: User
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
                
                Button(action: { showImagePicker = true }) {
                    Image(systemName: "camera.circle.fill")
                        .foregroundColor(.blue)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            
            Text(user.displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("@\(user.username)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                VStack {
                    Text("\(user.flagHistory.count)")
                        .font(.headline)
                    Text("Flags")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack {
                    Text("\(user.supportInteractions.count)")
                        .font(.headline)
                    Text("Support")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
}

struct ProfileView: View {
    let user: User
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ProfileHeader(user: user)
                
                Picker("Profile Sections", selection: $selectedTab) {
                    Text("Activity").tag(0)
                    Text("Settings").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    ProfileActivityView(user: user)
                } else {
                    SettingsView()
                }
            }
        }
    }
}

struct ProfileActivityView: View {
    let user: User
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Recent Activity")
            
            if !user.flagHistory.isEmpty {
                ForEach(user.flagHistory.prefix(5), id: \.date) { flag in
                    ActivityItem(
                        icon: "flag.fill",
                        title: "Flagged Content",
                        subtitle: flag.reason,
                        date: flag.date
                    )
                }
            }
            
            if !user.supportInteractions.isEmpty {
                ForEach(user.supportInteractions.prefix(5), id: \.ticketId) { interaction in
                    ActivityItem(
                        icon: "questionmark.circle.fill",
                        title: "Support Ticket",
                        subtitle: interaction.type,
                        date: interaction.date
                    )
                }
            }
        }
        .padding()
    }
}

// MARK: - Settings Components
struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("language") private var language = "English"
    @AppStorage("soundEffects") private var soundEffects = true
    @AppStorage("vibration") private var vibration = true
    @AppStorage("dataSaver") private var dataSaver = false
    
    var body: some View {
        VStack(spacing: 0) {
            SettingsSection(title: "Preferences") {
                ToggleRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    isOn: $notificationsEnabled
                )
                
                ToggleRow(
                    icon: "moon.fill",
                    title: "Dark Mode",
                    isOn: $darkModeEnabled
                )
                
                ToggleRow(
                    icon: "speaker.wave.2.fill",
                    title: "Sound Effects",
                    isOn: $soundEffects
                )
                
                ToggleRow(
                    icon: "iphone.radiowaves.left.and.right",
                    title: "Vibration",
                    isOn: $vibration
                )
                
                ToggleRow(
                    icon: "tortoise.fill",
                    title: "Data Saver",
                    isOn: $dataSaver
                )
                
                NavigationRow(
                    icon: "globe",
                    title: "Language & Region",
                    value: language
                ) {
                    LanguageSettingsView()
                }
            }
            
            SettingsSection(title: "Account") {
                NavigationRow(
                    icon: "lock.fill",
                    title: "Privacy",
                    value: ""
                ) {
                    PrivacySettingsView()
                }
                
                NavigationRow(
                    icon: "key.fill",
                    title: "Security",
                    value: ""
                ) {
                    SecuritySettingsView()
                }
                
                NavigationRow(
                    icon: "paintbrush.fill",
                    title: "Customize Profile",
                    value: ""
                ) {
                    ProfileCustomizationView()
                }
            }
            
            SettingsSection(title: "Support") {
                NavigationRow(
                    icon: "questionmark.circle.fill",
                    title: "Help Center",
                    value: ""
                ) {
                    HelpCenterView()
                }
                
                NavigationRow(
                    icon: "envelope.fill",
                    title: "Contact Support",
                    value: ""
                ) {
                    ContactSupportView()
                }
                
                NavigationRow(
                    icon: "doc.text.fill",
                    title: "Terms & Privacy",
                    value: ""
                ) {
                    TermsAndPrivacyView()
                }
            }
            
            SettingsSection(title: "Notifications") {
                NavigationRow(
                    icon: "bell.fill",
                    title: "Notification Settings",
                    value: ""
                ) {
                    NotificationSettingsView()
                }
            }
            
            SettingsSection(title: "Appearance") {
                NavigationRow(
                    icon: "paintbrush.fill",
                    title: "Theme",
                    value: ""
                ) {
                    ThemeSettingsView()
                }
            }
            
            SettingsSection(title: "Data") {
                NavigationRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Data Management",
                    value: ""
                ) {
                    DataManagementView()
                }
            }
            
            SettingsSection(title: "Accessibility") {
                NavigationRow(
                    icon: "figure.stand",
                    title: "Accessibility",
                    value: ""
                ) {
                    AccessibilitySettingsView()
                }
            }
            
            Button(action: {
                // Handle logout
            }) {
                HStack {
                    Image(systemName: "arrow.right.square.fill")
                        .foregroundColor(.red)
                    Text("Log Out")
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            }
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 8)
            
            content
        }
    }
}

struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct NavigationRow<Destination: View>: View {
    let icon: String
    let title: String
    let value: String
    let destination: () -> Destination
    
    var body: some View {
        NavigationLink(destination: destination()) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                Text(title)
                
                Spacer()
                
                Text(value)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 8)
    }
}

struct ActivityItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let date: Date
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formattedDate(date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
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
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Settings Navigation Destinations
struct PrivacySettingsView: View {
    @AppStorage("profileVisibility") private var profileVisibility = "Public"
    @AppStorage("showActivityStatus") private var showActivityStatus = true
    @AppStorage("allowFriendRequests") private var allowFriendRequests = true
    
    var body: some View {
        List {
            Section(header: Text("Profile Visibility")) {
                Picker("Who can see your profile", selection: $profileVisibility) {
                    Text("Public").tag("Public")
                    Text("Friends Only").tag("Friends Only")
                    Text("Private").tag("Private")
                }
            }
            
            Section(header: Text("Activity")) {
                Toggle("Show Activity Status", isOn: $showActivityStatus)
                Toggle("Allow Friend Requests", isOn: $allowFriendRequests)
            }
        }
        .navigationTitle("Privacy")
    }
}

struct SecuritySettingsView: View {
    @AppStorage("twoFactorEnabled") private var twoFactorEnabled = false
    @AppStorage("loginAlerts") private var loginAlerts = true
    @AppStorage("biometricAuth") private var biometricAuth = false
    @AppStorage("sessionTimeout") private var sessionTimeout = 30
    @AppStorage("maxLoginAttempts") private var maxLoginAttempts = 5
    @State private var showChangePassword = false
    
    var body: some View {
        List {
            Section(header: Text("Authentication")) {
                Toggle("Two-Factor Authentication", isOn: $twoFactorEnabled)
                Toggle("Biometric Authentication", isOn: $biometricAuth)
                Toggle("Login Alerts", isOn: $loginAlerts)
                
                Button("Change Password") {
                    showChangePassword = true
                }
            }
            
            Section(header: Text("Security Settings")) {
                Picker("Session Timeout", selection: $sessionTimeout) {
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("1 hour").tag(60)
                    Text("Never").tag(0)
                }
                
                Picker("Max Login Attempts", selection: $maxLoginAttempts) {
                    Text("3 attempts").tag(3)
                    Text("5 attempts").tag(5)
                    Text("10 attempts").tag(10)
                }
            }
            
            Section(header: Text("Active Sessions")) {
                ForEach(1...3, id: \.self) { session in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("iPhone \(session)")
                                .font(.subheadline)
                            Text("Last active: 2 hours ago")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("End Session") {
                            // Handle ending session
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Security")
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
    }
}

struct ChangePasswordView: View {
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Password")) {
                    SecureField("Enter current password", text: $currentPassword)
                }
                
                Section(header: Text("New Password")) {
                    SecureField("Enter new password", text: $newPassword)
                    SecureField("Confirm new password", text: $confirmPassword)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    // Handle password change
                    dismiss()
                }
            )
        }
    }
}

struct LanguageSettingsView: View {
    @AppStorage("language") private var language = "English"
    @AppStorage("region") private var region = "United States"
    
    var body: some View {
        List {
            Section(header: Text("Language")) {
                Picker("App Language", selection: $language) {
                    Text("English").tag("English")
                    Text("Spanish").tag("Spanish")
                    Text("French").tag("French")
                    Text("German").tag("German")
                }
            }
            
            Section(header: Text("Region")) {
                Picker("Region", selection: $region) {
                    Text("United States").tag("United States")
                    Text("United Kingdom").tag("United Kingdom")
                    Text("Canada").tag("Canada")
                    Text("Australia").tag("Australia")
                }
            }
        }
        .navigationTitle("Language & Region")
    }
}

// MARK: - Enhanced Profile Components
struct ProfileCustomizationView: View {
    @State private var bio = ""
    @State private var interests: [String] = []
    @State private var newInterest = ""
    @State private var showInterestAlert = false
    
    var body: some View {
        List {
            Section(header: Text("About")) {
                TextEditor(text: $bio)
                    .frame(height: 100)
            }
            
            Section(header: Text("Interests")) {
                ForEach(interests, id: \.self) { interest in
                    Text(interest)
                }
                .onDelete { indexSet in
                    interests.remove(atOffsets: indexSet)
                }
                
                HStack {
                    TextField("Add interest", text: $newInterest)
                    Button("Add") {
                        if !newInterest.isEmpty {
                            interests.append(newInterest)
                            newInterest = ""
                        }
                    }
                }
            }
            
            Section(header: Text("Social Links")) {
                NavigationLink("Add Social Media Links") {
                    SocialLinksView()
                }
            }
        }
        .navigationTitle("Customize Profile")
    }
}

struct SocialLinksView: View {
    @State private var instagram = ""
    @State private var twitter = ""
    @State private var linkedin = ""
    
    var body: some View {
        List {
            Section(header: Text("Social Media")) {
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.purple)
                    TextField("Instagram", text: $instagram)
                }
                
                HStack {
                    Image(systemName: "bird.fill")
                        .foregroundColor(.blue)
                    TextField("Twitter", text: $twitter)
                }
                
                HStack {
                    Image(systemName: "link.circle.fill")
                        .foregroundColor(.blue)
                    TextField("LinkedIn", text: $linkedin)
                }
            }
        }
        .navigationTitle("Social Links")
    }
}

// Add new support views
struct HelpCenterView: View {
    var body: some View {
        List {
            Section(header: Text("Frequently Asked Questions")) {
                NavigationLink("Account Settings") {
                    FAQDetailView(title: "Account Settings")
                }
                NavigationLink("Privacy & Security") {
                    FAQDetailView(title: "Privacy & Security")
                }
                NavigationLink("Troubleshooting") {
                    FAQDetailView(title: "Troubleshooting")
                }
            }
        }
        .navigationTitle("Help Center")
    }
}

struct FAQDetailView: View {
    let title: String
    
    var body: some View {
        List {
            Section {
                Text("Common questions and answers about \(title)")
            }
        }
        .navigationTitle(title)
    }
}

struct ContactSupportView: View {
    @State private var subject = ""
    @State private var message = ""
    @State private var showAttachmentPicker = false
    
    var body: some View {
        Form {
            Section(header: Text("Subject")) {
                TextField("Enter subject", text: $subject)
            }
            
            Section(header: Text("Message")) {
                TextEditor(text: $message)
                    .frame(height: 200)
            }
            
            Section {
                Button("Attach Screenshot") {
                    showAttachmentPicker = true
                }
            }
            
            Section {
                Button("Submit") {
                    // Handle submission
                }
            }
        }
        .navigationTitle("Contact Support")
        .sheet(isPresented: $showAttachmentPicker) {
            ImagePicker(image: .constant(nil))
        }
    }
}

struct TermsAndPrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit...")
                
                Text("Privacy Policy")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit...")
            }
            .padding()
        }
        .navigationTitle("Terms & Privacy")
    }
}

// MARK: - Enhanced Settings Components
struct NotificationSettingsView: View {
    @AppStorage("pushNotifications") private var pushNotifications = true
    @AppStorage("emailNotifications") private var emailNotifications = true
    @AppStorage("inAppNotifications") private var inAppNotifications = true
    @AppStorage("notificationSound") private var notificationSound = true
    @AppStorage("notificationVibration") private var notificationVibration = true
    
    var body: some View {
        List {
            Section(header: Text("Notification Types")) {
                Toggle("Push Notifications", isOn: $pushNotifications)
                Toggle("Email Notifications", isOn: $emailNotifications)
                Toggle("In-App Notifications", isOn: $inAppNotifications)
            }
            
            Section(header: Text("Notification Preferences")) {
                Toggle("Sound", isOn: $notificationSound)
                Toggle("Vibration", isOn: $notificationVibration)
            }
            
            Section(header: Text("Notification Schedule")) {
                NavigationLink("Quiet Hours") {
                    QuietHoursView()
                }
            }
        }
        .navigationTitle("Notifications")
    }
}

struct QuietHoursView: View {
    @AppStorage("quietHoursEnabled") private var quietHoursEnabled = false
    @AppStorage("quietHoursStart") private var quietHoursStart = Date()
    @AppStorage("quietHoursEnd") private var quietHoursEnd = Date()
    
    var body: some View {
        List {
            Toggle("Enable Quiet Hours", isOn: $quietHoursEnabled)
            
            if quietHoursEnabled {
                DatePicker("Start Time", selection: $quietHoursStart, displayedComponents: .hourAndMinute)
                DatePicker("End Time", selection: $quietHoursEnd, displayedComponents: .hourAndMinute)
            }
        }
        .navigationTitle("Quiet Hours")
    }
}

struct ThemeSettingsView: View {
    @AppStorage("selectedTheme") private var selectedTheme = "System"
    @AppStorage("accentColor") private var accentColor = "Blue"
    @AppStorage("fontSize") private var fontSize = "Medium"
    
    let themes = ["System", "Light", "Dark"]
    let colors = ["Blue", "Purple", "Green", "Red", "Orange"]
    let fontSizes = ["Small", "Medium", "Large"]
    
    var body: some View {
        List {
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(themes, id: \.self) { theme in
                        Text(theme)
                    }
                }
                
                Picker("Accent Color", selection: $accentColor) {
                    ForEach(colors, id: \.self) { color in
                        Text(color)
                    }
                }
                
                Picker("Font Size", selection: $fontSize) {
                    ForEach(fontSizes, id: \.self) { size in
                        Text(size)
                    }
                }
            }
            
            Section(header: Text("Customization")) {
                NavigationLink("Custom Colors") {
                    CustomColorsView()
                }
                
                NavigationLink("Font Settings") {
                    FontSettingsView()
                }
            }
        }
        .navigationTitle("Theme")
    }
}

struct CustomColorsView: View {
    @AppStorage("primaryColor") private var primaryColor = "Blue"
    @AppStorage("secondaryColor") private var secondaryColor = "Gray"
    @AppStorage("backgroundColor") private var backgroundColor = "White"
    
    var body: some View {
        List {
            ColorPicker("Primary Color", selection: .constant(Color.blue))
            ColorPicker("Secondary Color", selection: .constant(Color.gray))
            ColorPicker("Background Color", selection: .constant(Color.white))
        }
        .navigationTitle("Custom Colors")
    }
}

struct FontSettingsView: View {
    @AppStorage("fontFamily") private var fontFamily = "System"
    @AppStorage("fontWeight") private var fontWeight = "Regular"
    @AppStorage("lineSpacing") private var lineSpacing = 1.0
    
    var body: some View {
        List {
            Picker("Font Family", selection: $fontFamily) {
                Text("System").tag("System")
                Text("Serif").tag("Serif")
                Text("Monospace").tag("Monospace")
            }
            
            Picker("Font Weight", selection: $fontWeight) {
                Text("Regular").tag("Regular")
                Text("Medium").tag("Medium")
                Text("Bold").tag("Bold")
            }
            
            VStack {
                Text("Line Spacing")
                Slider(value: $lineSpacing, in: 0.8...2.0, step: 0.1)
            }
        }
        .navigationTitle("Font Settings")
    }
}

struct DataManagementView: View {
    @State private var showExportOptions = false
    @State private var showImportOptions = false
    @State private var showBackupOptions = false
    
    var body: some View {
        List {
            Section(header: Text("Data Export")) {
                Button("Export Profile Data") {
                    showExportOptions = true
                }
                
                Button("Export Activity History") {
                    showExportOptions = true
                }
            }
            
            Section(header: Text("Data Import")) {
                Button("Import Profile Data") {
                    showImportOptions = true
                }
                
                Button("Import Activity History") {
                    showImportOptions = true
                }
            }
            
            Section(header: Text("Backup & Restore")) {
                Button("Create Backup") {
                    showBackupOptions = true
                }
                
                Button("Restore from Backup") {
                    showBackupOptions = true
                }
            }
        }
        .navigationTitle("Data Management")
        .sheet(isPresented: $showExportOptions) {
            ExportOptionsView()
        }
        .sheet(isPresented: $showImportOptions) {
            ImportOptionsView()
        }
        .sheet(isPresented: $showBackupOptions) {
            BackupOptionsView()
        }
    }
}

struct ExportOptionsView: View {
    @State private var includeProfile = true
    @State private var includeActivity = true
    @State private var includeSettings = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Data to Export")) {
                    Toggle("Profile Information", isOn: $includeProfile)
                    Toggle("Activity History", isOn: $includeActivity)
                    Toggle("App Settings", isOn: $includeSettings)
                }
                
                Section {
                    Button("Export") {
                        // Handle export
                        dismiss()
                    }
                }
            }
            .navigationTitle("Export Options")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

struct ImportOptionsView: View {
    @State private var selectedFile: URL?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Import Options")) {
                    Button("Select File") {
                        // Handle file selection
                    }
                    
                    if let file = selectedFile {
                        Text(file.lastPathComponent)
                    }
                }
                
                Section {
                    Button("Import") {
                        // Handle import
                        dismiss()
                    }
                }
            }
            .navigationTitle("Import Options")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

struct BackupOptionsView: View {
    @State private var backupFrequency = "Daily"
    @State private var includeMedia = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Backup Settings")) {
                    Picker("Backup Frequency", selection: $backupFrequency) {
                        Text("Daily").tag("Daily")
                        Text("Weekly").tag("Weekly")
                        Text("Monthly").tag("Monthly")
                    }
                    
                    Toggle("Include Media Files", isOn: $includeMedia)
                }
                
                Section {
                    Button("Create Backup Now") {
                        // Handle backup
                        dismiss()
                    }
                }
            }
            .navigationTitle("Backup Options")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

struct AccessibilitySettingsView: View {
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("increaseContrast") private var increaseContrast = false
    @AppStorage("voiceOverEnabled") private var voiceOverEnabled = false
    @AppStorage("largerText") private var largerText = false
    
    var body: some View {
        List {
            Section(header: Text("Visual")) {
                Toggle("Reduce Motion", isOn: $reduceMotion)
                Toggle("Increase Contrast", isOn: $increaseContrast)
                Toggle("Larger Text", isOn: $largerText)
            }
            
            Section(header: Text("Audio")) {
                Toggle("VoiceOver", isOn: $voiceOverEnabled)
            }
            
            Section(header: Text("Interaction")) {
                NavigationLink("Touch Accommodations") {
                    TouchAccommodationsView()
                }
            }
        }
        .navigationTitle("Accessibility")
    }
}

struct TouchAccommodationsView: View {
    @AppStorage("touchDuration") private var touchDuration = 0.5
    @AppStorage("ignoreRepeat") private var ignoreRepeat = true
    @AppStorage("tapAssistance") private var tapAssistance = false
    
    var body: some View {
        List {
            VStack {
                Text("Touch Duration")
                Slider(value: $touchDuration, in: 0.1...1.0, step: 0.1)
            }
            
            Toggle("Ignore Repeat", isOn: $ignoreRepeat)
            Toggle("Tap Assistance", isOn: $tapAssistance)
        }
        .navigationTitle("Touch Accommodations")
    }
}

// MARK: - Navigation Components
enum Tab: String, CaseIterable {
    case home = "Home"
    case explore = "Explore"
    case create = "Create"
    case notifications = "Notifications"
    case profile = "Profile"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .explore: return "magnifyingglass"
        case .create: return "plus.circle.fill"
        case .notifications: return "bell.fill"
        case .profile: return "person.fill"
        }
    }
}

enum Route: Hashable {
    case home
    case explore
    case create
    case notifications
    case profile
    case settings
    case userDetail(String) // User ID
    case postDetail(String) // Post ID
    case conversation(String) // Conversation ID
    case search(String?) // Search query
    case settingsSection(String) // Settings section
    case storyDetail(String) // Story ID
    case hashtag(String) // Hashtag name
    case location(String) // Location ID
    case media(String) // Media ID
    case commentThread(String) // Comment ID
    case savedPosts
    case bookmarkedPosts
    case likedPosts
    case following
    case followers
    case editProfile
    case changePassword
    case privacySettings
    case securitySettings
    case notificationSettings
    case helpCenter
    case contactSupport
    case termsAndPrivacy
    case about
    case feedback
    
    static func == (lhs: Route, rhs: Route) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home): return true
        case (.explore, .explore): return true
        case (.create, .create): return true
        case (.notifications, .notifications): return true
        case (.profile, .profile): return true
        case (.settings, .settings): return true
        case (.userDetail(let id1), .userDetail(let id2)): return id1 == id2
        case (.postDetail(let id1), .postDetail(let id2)): return id1 == id2
        case (.conversation(let id1), .conversation(let id2)): return id1 == id2
        case (.search(let q1), .search(let q2)): return q1 == q2
        case (.settingsSection(let s1), .settingsSection(let s2)): return s1 == s2
        case (.storyDetail(let id1), .storyDetail(let id2)): return id1 == id2
        case (.hashtag(let name1), .hashtag(let name2)): return name1 == name2
        case (.location(let id1), .location(let id2)): return id1 == id2
        case (.media(let id1), .media(let id2)): return id1 == id2
        case (.commentThread(let id1), .commentThread(let id2)): return id1 == id2
        case (.savedPosts, .savedPosts): return true
        case (.bookmarkedPosts, .bookmarkedPosts): return true
        case (.likedPosts, .likedPosts): return true
        case (.following, .following): return true
        case (.followers, .followers): return true
        case (.editProfile, .editProfile): return true
        case (.changePassword, .changePassword): return true
        case (.privacySettings, .privacySettings): return true
        case (.securitySettings, .securitySettings): return true
        case (.notificationSettings, .notificationSettings): return true
        case (.helpCenter, .helpCenter): return true
        case (.contactSupport, .contactSupport): return true
        case (.termsAndPrivacy, .termsAndPrivacy): return true
        case (.about, .about): return true
        case (.feedback, .feedback): return true
        default: return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .home: hasher.combine("home")
        case .explore: hasher.combine("explore")
        case .create: hasher.combine("create")
        case .notifications: hasher.combine("notifications")
        case .profile: hasher.combine("profile")
        case .settings: hasher.combine("settings")
        case .userDetail(let id): hasher.combine("userDetail-\(id)")
        case .postDetail(let id): hasher.combine("postDetail-\(id)")
        case .conversation(let id): hasher.combine("conversation-\(id)")
        case .search(let query): hasher.combine("search-\(query ?? "")")
        case .settingsSection(let section): hasher.combine("settingsSection-\(section)")
        case .storyDetail(let id): hasher.combine("storyDetail-\(id)")
        case .hashtag(let name): hasher.combine("hashtag-\(name)")
        case .location(let id): hasher.combine("location-\(id)")
        case .media(let id): hasher.combine("media-\(id)")
        case .commentThread(let id): hasher.combine("commentThread-\(id)")
        case .savedPosts: hasher.combine("savedPosts")
        case .bookmarkedPosts: hasher.combine("bookmarkedPosts")
        case .likedPosts: hasher.combine("likedPosts")
        case .following: hasher.combine("following")
        case .followers: hasher.combine("followers")
        case .editProfile: hasher.combine("editProfile")
        case .changePassword: hasher.combine("changePassword")
        case .privacySettings: hasher.combine("privacySettings")
        case .securitySettings: hasher.combine("securitySettings")
        case .notificationSettings: hasher.combine("notificationSettings")
        case .helpCenter: hasher.combine("helpCenter")
        case .contactSupport: hasher.combine("contactSupport")
        case .termsAndPrivacy: hasher.combine("termsAndPrivacy")
        case .about: hasher.combine("about")
        case .feedback: hasher.combine("feedback")
        }
    }
}

class NavigationManager: ObservableObject {
    @Published var currentTab: Tab = .home
    @Published var path: [Route] = []
    @Published var presentedSheet: Route?
    @Published var presentedFullScreenCover: Route?
    
    // Navigation state persistence
    @AppStorage("lastTab") private var lastTab: String = Tab.home.rawValue
    @AppStorage("lastPath") private var lastPath: String = ""
    
    init() {
        // Restore last navigation state
        if let tab = Tab(rawValue: lastTab) {
            currentTab = tab
        }
        
        if let pathData = lastPath.data(using: .utf8),
           let decodedPath = try? JSONDecoder().decode([Route].self, from: pathData) {
            path = decodedPath
        }
    }
    
    func navigate(to route: Route) {
        path.append(route)
        saveNavigationState()
    }
    
    func presentSheet(_ route: Route) {
        presentedSheet = route
        saveNavigationState()
    }
    
    func presentFullScreenCover(_ route: Route) {
        presentedFullScreenCover = route
        saveNavigationState()
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
            saveNavigationState()
        }
    }
    
    func popToRoot() {
        path.removeAll()
        saveNavigationState()
    }
    
    private func saveNavigationState() {
        // Save current tab
        lastTab = currentTab.rawValue
        
        // Save navigation path
        if let pathData = try? JSONEncoder().encode(path),
           let pathString = String(data: pathData, encoding: .utf8) {
            lastPath = pathString
        }
    }
    
    func handleDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else { return }
        
        // Parse query parameters
        let queryItems = components.queryItems ?? []
        let queryDict = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value) })
        
        switch host {
        case "user":
            if let id = components.path.components(separatedBy: "/").last {
                navigate(to: .userDetail(id))
            }
        case "post":
            if let id = components.path.components(separatedBy: "/").last {
                navigate(to: .postDetail(id))
            }
        case "settings":
            if let section = components.path.components(separatedBy: "/").last {
                navigate(to: .settingsSection(section))
            }
        case "search":
            if let query = queryDict["q"] {
                navigate(to: .search(query))
            }
        case "conversation":
            if let id = components.path.components(separatedBy: "/").last {
                navigate(to: .conversation(id))
            }
        case "profile":
            if let id = queryDict["id"] {
                navigate(to: .userDetail(id))
            }
        case "create":
            if let type = queryDict["type"] {
                switch type {
                case "post":
                    presentFullScreenCover(.create)
                case "story":
                    presentFullScreenCover(.create)
                default:
                    break
                }
            }
        case "notifications":
            if let type = queryDict["type"] {
                switch type {
                case "all":
                    navigate(to: .notifications)
                case "mentions":
                    navigate(to: .notifications)
                case "follows":
                    navigate(to: .notifications)
                default:
                    break
                }
            }
        case "explore":
            if let category = queryDict["category"] {
                navigate(to: .explore)
            }
        case "home":
            if let feed = queryDict["feed"] {
                switch feed {
                case "following":
                    navigate(to: .home)
                case "for-you":
                    navigate(to: .home)
                default:
                    break
                }
            }
        case "story":
            if let id = components.path.components(separatedBy: "/").last {
                navigate(to: .storyDetail(id))
            }
        case "hashtag":
            if let name = components.path.components(separatedBy: "/").last {
                navigate(to: .hashtag(name))
            }
        case "location":
            if let id = components.path.components(separatedBy: "/").last {
                navigate(to: .location(id))
            }
        case "media":
            if let id = components.path.components(separatedBy: "/").last {
                navigate(to: .media(id))
            }
        case "comment":
            if let id = components.path.components(separatedBy: "/").last {
                navigate(to: .commentThread(id))
            }
        case "saved":
            navigate(to: .savedPosts)
        case "bookmarked":
            navigate(to: .bookmarkedPosts)
        case "liked":
            navigate(to: .likedPosts)
        case "following":
            navigate(to: .following)
        case "followers":
            navigate(to: .followers)
        case "edit":
            navigate(to: .editProfile)
        case "change":
            navigate(to: .changePassword)
        case "privacy":
            navigate(to: .privacySettings)
        case "security":
            navigate(to: .securitySettings)
        case "notification":
            navigate(to: .notificationSettings)
        case "help":
            navigate(to: .helpCenter)
        case "contact":
            navigate(to: .contactSupport)
        case "terms":
            navigate(to: .termsAndPrivacy)
        case "about":
            navigate(to: .about)
        case "feedback":
            navigate(to: .feedback)
        default:
            break
        }
    }
}

struct MainTabView: View {
    @StateObject private var navigationManager = NavigationManager()
    
    var body: some View {
        TabView(selection: $navigationManager.currentTab) {
            HomeView()
                .tabItem {
                    Label(Tab.home.rawValue, systemImage: Tab.home.icon)
                }
                .tag(Tab.home)
            
            ExploreView()
                .tabItem {
                    Label(Tab.explore.rawValue, systemImage: Tab.explore.icon)
                }
                .tag(Tab.explore)
            
            CreateView()
                .tabItem {
                    Label(Tab.create.rawValue, systemImage: Tab.create.icon)
                }
                .tag(Tab.create)
            
            NotificationsView()
                .tabItem {
                    Label(Tab.notifications.rawValue, systemImage: Tab.notifications.icon)
                }
                .tag(Tab.notifications)
            
            ProfileView()
                .tabItem {
                    Label(Tab.profile.rawValue, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .environmentObject(navigationManager)
    }
}

struct NavigationContainer<Content: View>: View {
    let content: Content
    @EnvironmentObject private var navigationManager: NavigationManager
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            content
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .home:
                        HomeView()
                    case .explore:
                        ExploreView()
                    case .create:
                        CreateView()
                    case .notifications:
                        NotificationsView()
                    case .profile:
                        ProfileView()
                    case .settings:
                        SettingsView()
                    case .userDetail(let id):
                        UserDetailView(userId: id)
                    case .postDetail(let id):
                        PostDetailView(postId: id)
                    case .conversation(let id):
                        ConversationView(conversationId: id)
                    case .search(let query):
                        SearchView(query: query)
                    case .settingsSection(let section):
                        SettingsSectionView(section: section)
                    case .storyDetail(let id):
                        StoryDetailView(storyId: id)
                    case .hashtag(let name):
                        HashtagView(name: name)
                    case .location(let id):
                        LocationView(locationId: id)
                    case .media(let id):
                        MediaView(mediaId: id)
                    case .commentThread(let id):
                        CommentThreadView(commentId: id)
                    case .savedPosts:
                        SavedPostsView()
                    case .bookmarkedPosts:
                        BookmarkedPostsView()
                    case .likedPosts:
                        LikedPostsView()
                    case .following:
                        FollowingView()
                    case .followers:
                        FollowersView()
                    case .editProfile:
                        EditProfileView()
                    case .changePassword:
                        ChangePasswordView()
                    case .privacySettings:
                        PrivacySettingsView()
                    case .securitySettings:
                        SecuritySettingsView()
                    case .notificationSettings:
                        NotificationSettingsView()
                    case .helpCenter:
                        HelpCenterView()
                    case .contactSupport:
                        ContactSupportView()
                    case .termsAndPrivacy:
                        TermsAndPrivacyView()
                    case .about:
                        AboutView()
                    case .feedback:
                        FeedbackView()
                    }
                }
        }
        .sheet(item: $navigationManager.presentedSheet) { route in
            NavigationView {
                switch route {
                case .settings:
                    SettingsView()
                case .userDetail(let id):
                    UserDetailView(userId: id)
                case .postDetail(let id):
                    PostDetailView(postId: id)
                case .conversation(let id):
                    ConversationView(conversationId: id)
                case .search(let query):
                    SearchView(query: query)
                case .settingsSection(let section):
                    SettingsSectionView(section: section)
                case .storyDetail(let id):
                    StoryDetailView(storyId: id)
                case .hashtag(let name):
                    HashtagView(name: name)
                case .location(let id):
                    LocationView(locationId: id)
                case .media(let id):
                    MediaView(mediaId: id)
                case .commentThread(let id):
                    CommentThreadView(commentId: id)
                case .savedPosts:
                    SavedPostsView()
                case .bookmarkedPosts:
                    BookmarkedPostsView()
                case .likedPosts:
                    LikedPostsView()
                case .following:
                    FollowingView()
                case .followers:
                    FollowersView()
                case .editProfile:
                    EditProfileView()
                case .changePassword:
                    ChangePasswordView()
                case .privacySettings:
                    PrivacySettingsView()
                case .securitySettings:
                    SecuritySettingsView()
                case .notificationSettings:
                    NotificationSettingsView()
                case .helpCenter:
                    HelpCenterView()
                case .contactSupport:
                    ContactSupportView()
                case .termsAndPrivacy:
                    TermsAndPrivacyView()
                case .about:
                    AboutView()
                case .feedback:
                    FeedbackView()
                default:
                    EmptyView()
                }
            }
        }
        .fullScreenCover(item: $navigationManager.presentedFullScreenCover) { route in
            NavigationView {
                switch route {
                case .create:
                    CreateView()
                case .storyDetail(let id):
                    StoryDetailView(storyId: id)
                case .hashtag(let name):
                    HashtagView(name: name)
                case .location(let id):
                    LocationView(locationId: id)
                case .media(let id):
                    MediaView(mediaId: id)
                case .commentThread(let id):
                    CommentThreadView(commentId: id)
                case .savedPosts:
                    SavedPostsView()
                case .bookmarkedPosts:
                    BookmarkedPostsView()
                case .likedPosts:
                    LikedPostsView()
                case .following:
                    FollowingView()
                case .followers:
                    FollowersView()
                case .editProfile:
                    EditProfileView()
                case .changePassword:
                    ChangePasswordView()
                case .privacySettings:
                    PrivacySettingsView()
                case .securitySettings:
                    SecuritySettingsView()
                case .notificationSettings:
                    NotificationSettingsView()
                case .helpCenter:
                    HelpCenterView()
                case .contactSupport:
                    ContactSupportView()
                case .termsAndPrivacy:
                    TermsAndPrivacyView()
                case .about:
                    AboutView()
                case .feedback:
                    FeedbackView()
                default:
                    EmptyView()
                }
            }
        }
    }
}

// MARK: - Screen Transitions
struct SlideTransition: ViewModifier {
    let edge: Edge
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .transition(.asymmetric(
                insertion: .move(edge: edge),
                removal: .move(edge: edge)
            ))
            .animation(.easeInOut, value: isPresented)
    }
}

struct FadeTransition: ViewModifier {
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .transition(.opacity)
            .animation(.easeInOut, value: isPresented)
    }
}

struct ScaleTransition: ViewModifier {
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .transition(.scale)
            .animation(.spring(), value: isPresented)
    }
}

extension View {
    func slideTransition(edge: Edge, isPresented: Binding<Bool>) -> some View {
        modifier(SlideTransition(edge: edge, isPresented: isPresented))
    }
    
    func fadeTransition(isPresented: Binding<Bool>) -> some View {
        modifier(FadeTransition(isPresented: isPresented))
    }
    
    func scaleTransition(isPresented: Binding<Bool>) -> some View {
        modifier(ScaleTransition(isPresented: isPresented))
    }
}

// MARK: - Example Views
struct HomeView: View {
    var body: some View {
        Text("Home View")
            .navigationTitle("Home")
    }
}

struct ExploreView: View {
    var body: some View {
        Text("Explore View")
            .navigationTitle("Explore")
    }
}

struct CreateView: View {
    var body: some View {
        Text("Create View")
            .navigationTitle("Create")
    }
}

struct NotificationsView: View {
    var body: some View {
        Text("Notifications View")
            .navigationTitle("Notifications")
    }
}

struct UserDetailView: View {
    let userId: String
    
    var body: some View {
        Text("User Detail View: \(userId)")
            .navigationTitle("User Profile")
    }
}

struct PostDetailView: View {
    let postId: String
    
    var body: some View {
        Text("Post Detail View: \(postId)")
            .navigationTitle("Post")
    }
}

struct ConversationView: View {
    let conversationId: String
    
    var body: some View {
        Text("Conversation View: \(conversationId)")
            .navigationTitle("Chat")
    }
}

struct SearchView: View {
    let query: String?
    
    var body: some View {
        Text("Search View: \(query ?? "")")
            .navigationTitle("Search")
    }
}

struct SettingsSectionView: View {
    let section: String
    
    var body: some View {
        Text("Settings Section: \(section)")
            .navigationTitle(section)
    }
}

// MARK: - Preview
struct LengLengUIComponents_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UserListView()
                .previewLayout(.sizeThatFits)
                .padding()
            
            SearchBar(text: .constant(""))
                .previewLayout(.sizeThatFits)
                .padding()
            
            FilterButton(title: "Active", isSelected: true, action: {})
                .previewLayout(.sizeThatFits)
                .padding()
            
            StatusBadge(status: "active")
                .previewLayout(.sizeThatFits)
                .padding()
            
            ProfileView(user: User(
                id: "1",
                displayName: "John Doe",
                username: "johndoe",
                phoneNumber: "+1234567890",
                school: School(id: "1", name: "Example School"),
                accountStatus: "active",
                registrationDate: Date(),
                lastActive: Date(),
                flagHistory: [],
                supportInteractions: []
            ))
            .previewLayout(.sizeThatFits)
            .padding()
            
            SettingsView()
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}

// MARK: - Enhanced Local Storage Manager
class LocalStorageManager: ObservableObject {
    static let shared = LocalStorageManager()
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private let db = Firestore.firestore()
    
    // MARK: - User Data Caching
    @Published var cachedUser: User?
    @Published var cachedPosts: [Post] = []
    @Published var cachedConversations: [Conversation] = []
    @Published var cachedNotifications: [Notification] = []
    @Published var cachedMedia: [Media] = []
    @Published var cachedPreferences: UserPreferences?
    @Published var cachedSettings: AppSettings?
    
    // MARK: - Offline Data
    @Published var offlinePosts: [Post] = []
    @Published var offlineMessages: [Message] = []
    @Published var offlineActions: [UserAction] = []
    @Published var offlineMedia: [Media] = []
    
    // MARK: - Sync Status
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    @Published var syncProgress: Double = 0
    
    // MARK: - Version Control
    private var offlineDataVersion: Int = 1
    private var lastServerVersion: Int = 0
    
    private init() {
        loadCachedData()
        setupOfflineListeners()
        setupCompression()
    }
    
    // MARK: - Enhanced User Data Caching
    func cacheUser(_ user: User) {
        cachedUser = user
        if let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: "cachedUser")
        }
    }
    
    func cachePosts(_ posts: [Post]) {
        cachedPosts = posts
        if let data = try? JSONEncoder().encode(posts) {
            userDefaults.set(data, forKey: "cachedPosts")
        }
    }
    
    func cacheMedia(_ media: [Media]) {
        cachedMedia = media
        if let data = try? JSONEncoder().encode(media) {
            userDefaults.set(data, forKey: "cachedMedia")
        }
    }
    
    func cachePreferences(_ preferences: UserPreferences) {
        cachedPreferences = preferences
        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: "cachedPreferences")
        }
    }
    
    func cacheSettings(_ settings: AppSettings) {
        cachedSettings = settings
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: "cachedSettings")
        }
    }
    
    // MARK: - Enhanced Offline Functionality
    func saveOfflinePost(_ post: Post) {
        offlinePosts.append(post)
        saveOfflineData()
    }
    
    func saveOfflineMedia(_ media: Media) {
        offlineMedia.append(media)
        saveOfflineData()
    }
    
    private func saveOfflineData() {
        let offlineData = OfflineData(
            version: offlineDataVersion,
            posts: offlinePosts,
            messages: offlineMessages,
            actions: offlineActions,
            media: offlineMedia
        )
        
        if let data = try? JSONEncoder().encode(offlineData),
           let compressedData = compressData(data),
           let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsURL.appendingPathComponent("offlineData.json")
            try? compressedData.write(to: fileURL)
        }
    }
    
    private func loadOfflineData() {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsURL.appendingPathComponent("offlineData.json")
        
        if let compressedData = try? Data(contentsOf: fileURL),
           let data = decompressData(compressedData),
           let offlineData = try? JSONDecoder().decode(OfflineData.self, from: data) {
            offlinePosts = offlineData.posts
            offlineMessages = offlineData.messages
            offlineActions = offlineData.actions
            offlineMedia = offlineData.media
            offlineDataVersion = offlineData.version
        }
    }
    
    // MARK: - Enhanced Data Synchronization
    func syncData() async {
        guard !isSyncing else { return }
        isSyncing = true
        syncProgress = 0
        
        do {
            // Check server version
            let serverVersion = try await db.collection("versions").document("offlineData").getDocument().data()?["version"] as? Int ?? 0
            
            if serverVersion > lastServerVersion {
                // Server has newer data, resolve conflicts
                try await resolveConflicts()
            }
            
            // Sync offline posts with conflict resolution
            for (index, post) in offlinePosts.enumerated() {
                let serverPost = try await db.collection("posts").document(post.id).getDocument()
                if let serverData = serverPost.data() {
                    let resolvedPost = resolvePostConflict(local: post, server: serverData)
                    try await db.collection("posts").document(post.id).setData(from: resolvedPost)
                } else {
                    try await db.collection("posts").document(post.id).setData(from: post)
                }
                syncProgress = Double(index + 1) / Double(offlinePosts.count)
            }
            
            // Sync offline media with compression
            for media in offlineMedia {
                if let compressedData = compressData(media.data) {
                    try await db.collection("media").document(media.id).setData([
                        "data": compressedData,
                        "type": media.type,
                        "timestamp": media.timestamp
                    ])
                }
            }
            
            // Clear offline data after successful sync
            offlinePosts.removeAll()
            offlineMessages.removeAll()
            offlineActions.removeAll()
            offlineMedia.removeAll()
            saveOfflineData()
            
            // Update versions
            lastServerVersion = serverVersion
            offlineDataVersion += 1
            try await db.collection("versions").document("offlineData").setData([
                "version": offlineDataVersion,
                "lastSync": Date()
            ])
            
            // Update last sync date
            lastSyncDate = Date()
            userDefaults.set(lastSyncDate, forKey: "lastSyncDate")
            
        } catch {
            syncError = error
        }
        
        isSyncing = false
        syncProgress = 0
    }
    
    // MARK: - Conflict Resolution
    private func resolveConflicts() async throws {
        // Implement conflict resolution logic
        // This is a placeholder - you'll need to implement actual conflict resolution
    }
    
    private func resolvePostConflict(local: Post, server: [String: Any]) -> Post {
        // Implement post conflict resolution
        // This is a placeholder - you'll need to implement actual conflict resolution
        return local
    }
    
    // MARK: - Data Compression
    private func compressData(_ data: Data) -> Data? {
        // Implement data compression
        // This is a placeholder - you'll need to implement actual compression
        return data
    }
    
    private func decompressData(_ data: Data) -> Data? {
        // Implement data decompression
        // This is a placeholder - you'll need to implement actual decompression
        return data
    }
    
    private func setupCompression() {
        // Setup compression settings
        // This is a placeholder - you'll need to implement actual compression setup
    }
    
    // MARK: - Data Cleanup
    func cleanupOldData() {
        // Remove old cached data
        let cacheLimit = 100 // MB
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        do {
            let resourceValues = try documentsURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let availableCapacity = resourceValues.volumeAvailableCapacityForImportantUsage {
                if availableCapacity < Int64(cacheLimit * 1024 * 1024) {
                    // Clean up old data
                    try? fileManager.removeItem(at: documentsURL.appendingPathComponent("oldData.json"))
                }
            }
        } catch {
            print("Error checking storage capacity: \(error)")
        }
    }
}

// MARK: - Additional Models
struct Media: Identifiable, Codable {
    let id: String
    let type: String
    let data: Data
    let timestamp: Date
}

struct UserPreferences: Codable {
    let theme: String
    let language: String
    let notifications: Bool
    let privacy: PrivacySettings
}

struct PrivacySettings: Codable {
    let profileVisibility: String
    let showActivityStatus: Bool
    let allowFriendRequests: Bool
}

struct AppSettings: Codable {
    let version: String
    let buildNumber: String
    let lastUpdate: Date
    let features: [String: Bool]
}

struct OfflineData: Codable {
    let version: Int
    let posts: [Post]
    let messages: [Message]
    let actions: [UserAction]
    let media: [Media]
}

// MARK: - Network Monitor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    
    private init() {
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        // Implement network monitoring logic
        // This is a placeholder - you'll need to implement actual network monitoring
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(networkStatusChanged),
            name: .networkStatusChanged,
            object: nil
        )
    }
    
    @objc private func networkStatusChanged() {
        // Update isConnected based on actual network status
    }
}

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}

// MARK: - Example Usage
struct ContentView: View {
    @StateObject private var storageManager = LocalStorageManager.shared
    
    var body: some View {
        VStack {
            if let user = storageManager.cachedUser {
                Text("Welcome, \(user.displayName)")
            }
            
            if !storageManager.offlinePosts.isEmpty {
                Text("\(storageManager.offlinePosts.count) posts pending sync")
                    .foregroundColor(.orange)
            }
            
            if storageManager.isSyncing {
                ProgressView("Syncing...")
            }
            
            if let error = storageManager.syncError {
                Text("Sync Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            Task {
                await storageManager.syncData()
            }
        }
    }
}

// ... existing code ... 