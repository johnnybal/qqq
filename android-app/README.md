# LengLeng Android App Deployment

This document explains how to deploy the LengLeng Android app for different environments.

## Prerequisites

- Android Studio Hedgehog | 2023.1.1 or later
- Android SDK 34 (Android 14)
- Gradle 8.0 or later
- ADB (Android Debug Bridge)
- Keystore file for signing release builds
- Git

## Environment Variables

For staging and production builds, you need to set the following environment variables:

```bash
export KEYSTORE_PASSWORD=your_keystore_password
export KEY_ALIAS=your_key_alias
export KEY_PASSWORD=your_key_password
```

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/johnnybal/qqq.git
   cd qqq/android-app
   ```

2. Configure Firebase:
   - Place your `google-services.json` file in the `app` directory
   - Update Firebase configuration in `app/build.gradle`

3. Build the project:
   ```bash
   ./gradlew build
   ```

## Deployment Scripts

### Development Deployment

To deploy a development build to a connected device:

```bash
./deploy-dev.sh
```

This will:
1. Clean the project
2. Build a debug APK
3. Install it on the connected device
4. Launch the app

### Staging Deployment

To create a staging release build:

```bash
./deploy-staging.sh
```

This will:
1. Clean the project
2. Build a signed release APK
3. Generate SHA-256 hash
4. Place artifacts in `deploy/staging/`

### Production Deployment

To create a production release build:

```bash
./deploy-prod.sh
```

This will:
1. Clean the project
2. Build signed release APK and AAB
3. Generate SHA-256 hashes
4. Generate version info
5. Place artifacts in `deploy/prod/`

To also upload to Google Play Console:

```bash
./deploy-prod.sh --upload
```

## Features

### Core Features
- User authentication
- Poll creation and voting
- Real-time notifications
- Social connections
- Profile management

### Technical Features
- Firebase integration
- Material Design 3
- Jetpack Compose
- Kotlin Coroutines
- Room Database
- WorkManager

## Dependencies

- Firebase BoM 32.7.0
  - Firebase Auth
  - Firebase Firestore
  - Firebase Cloud Messaging
  - Firebase Analytics
- AndroidX
  - Compose 1.5.0
  - Navigation 2.7.0
  - Room 2.6.0
  - WorkManager 2.9.0
- Kotlin 1.9.0
- Coroutines 1.7.3
- Material Design 3 1.1.1

## GitHub Integration

### Initial Setup

1. Create a new repository on GitHub
2. Initialize the local repository:
```bash
git init
git remote add origin <repository-url>
```

### Pushing Changes

To push changes to GitHub:

```bash
./push-to-github.sh
```

This will:
1. Check if Git is installed
2. Initialize repository if needed
3. Add all files
4. Commit changes with timestamp
5. Push to the main branch

## Troubleshooting

### Common Issues

1. **Build Fails**
   - Check Android Studio version
   - Verify Gradle version
   - Clean and rebuild project

2. **Firebase Issues**
   - Verify google-services.json
   - Check Firebase console
   - Ensure proper SHA-1/SHA-256 fingerprints

3. **Deployment Issues**
   - Check keystore configuration
   - Verify environment variables
   - Ensure proper signing configuration

### Getting Help

If you encounter any issues not covered here:
1. Check the build logs
2. Review Firebase console
3. Contact the development team

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details. 