# LengLeng iOS App

A social polling app that lets users participate in polls, receive notifications, and interact with other users.

## Prerequisites

Before building the app, ensure you have the following installed:

- Xcode 15.0 or later
- iOS 17.0 or later
- Swift Package Manager (for dependency management)
- Apple Developer Account (for device builds)

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/johnnybal/qqq.git
   cd qqq/LengLeng
   ```

2. Install dependencies:
   ```bash
   swift package resolve
   ```

3. Open the project:
   ```bash
   open LengLeng.xcodeproj
   ```

## Building the App

The project includes a build script that supports different environments and targets. The available options are:

### Environments
- `development`: For development and testing
- `staging`: For beta testing and internal distribution
- `production`: For App Store distribution

### Targets
- `simulator`: For running on iOS Simulator
- `device`: For creating IPA files for physical devices

### Build Commands

1. Make the build script executable:
   ```bash
   chmod +x scripts/build.sh
   ```

2. Run the build script with your desired environment and target:
   ```bash
   # For development simulator build
   ./scripts/build.sh development simulator

   # For staging device build
   ./scripts/build.sh staging device

   # For production device build
   ./scripts/build.sh production device
   ```

### Build Outputs

- Simulator builds will be available in the derived data folder
- Device builds will create IPA files in the `build` directory

## Configuration

Before building for devices, you need to:

1. Update the Team ID in the export options plist files:
   - `ExportOptions-development.plist`
   - `ExportOptions-staging.plist`
   - `ExportOptions-production.plist`

   Replace `YOUR_TEAM_ID` with your actual Apple Developer Team ID.

2. Ensure your Apple Developer account has the necessary certificates and provisioning profiles.

## Features

### Polls
- View and participate in polls
- Real-time vote counting
- Visual feedback for selected options
- Poll categories and expiration tracking
- Pull-to-refresh for latest polls

### User Experience
- Clean and intuitive interface
- Smooth voting animations
- Percentage-based results display
- Category-based organization
- Time remaining indicators

### Notifications
- Push notifications for poll updates
- Match notifications
- System alerts

### User Management
- User authentication
- Profile management
- Settings customization
- Social connections
- Invitation system
- Subscription management

## Architecture

The app follows MVVM architecture with the following structure:
- Features/
  - Polls/
    - PollsView.swift (SwiftUI)
    - PollSystem.swift (UIKit)
  - Notifications/
    - NotificationsSystem.swift
  - Profile/
    - ProfileView.swift
    - EditProfileView.swift
    - SettingsView.swift
    - UserProfileSystem.swift
  - Social/
    - SocialView.swift
    - SocialGraphSystem.swift
    - InviteFriendsView.swift
    - SubscriptionStatusView.swift
- Models/
  - Poll.swift
  - PollOption.swift
  - PollVote.swift
  - User.swift
  - Connection.swift
  - Invitation.swift
- Services/
  - FirebaseService.swift
  - UserService.swift
  - InvitationService.swift
  - SubscriptionService.swift
- Utils/

## Dependencies

- Firebase SDK 10.24.0
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseMessaging
  - FirebaseAnalytics

## Troubleshooting

### Common Issues

1. **Build Fails with Code Signing Errors**
   - Ensure you have valid certificates and provisioning profiles
   - Check your Team ID in the export options plist files
   - Verify your Apple Developer account status

2. **Dependencies Not Found**
   - Run `swift package resolve` again
   - Check your Swift version
   - Ensure you're opening the correct project file

3. **Simulator Build Fails**
   - Check if the specified simulator exists
   - Update the simulator name in the build script if needed

### Getting Help

If you encounter any issues not covered here:
1. Check the Xcode build logs
2. Verify your environment setup
3. Contact the development team

## Additional Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Swift Package Manager Documentation](https://www.swift.org/package-manager/)
- [Xcode Build System Guide](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/XcodeBuildSystem/300-Build_System_Overview/build_system_overview.html)

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 