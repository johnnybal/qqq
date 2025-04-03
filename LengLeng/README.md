# LengLeng iOS App

A social polling app that lets users create and participate in polls, receive notifications, and interact with other users.

## Setup Instructions

1. **Prerequisites**
   - Xcode 14.0 or later
   - iOS 15.0 or later
   - CocoaPods (optional, if using SPM)
   - Firebase account

2. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Add an iOS app to your Firebase project
   - Download the `GoogleService-Info.plist` file
   - Replace the placeholder `GoogleService-Info.plist` in the project with your downloaded file
   - Enable Authentication, Firestore, and Cloud Messaging in Firebase Console

3. **Project Setup**
   - Clone the repository
   - Open `LengLeng.xcodeproj`
   - Update the Bundle Identifier in Xcode project settings
   - Update the Team and Signing settings
   - Enable Push Notifications capability
   - Enable App Groups capability
   - Update the App Group identifier in entitlements

4. **Dependencies**
   The project uses Swift Package Manager for dependencies:
   - Firebase iOS SDK
   - Other dependencies are managed through SPM

5. **Build and Run**
   - Select your target device/simulator
   - Build and run the project (⌘R)

## Features

- User Authentication
- Poll Creation and Voting
- Push Notifications
- User Profiles
- Settings Management

## Architecture

The app follows MVVM architecture with the following structure:
- Features/
  - Notifications/
  - Polls/
  - Onboarding/
  - Profile/
- Models/
- Services/
- Utils/

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 