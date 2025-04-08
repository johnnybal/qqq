# Onboarding Flow Documentation

## Overview

The onboarding flow in LengLeng is designed to collect essential user information and preferences when a new user signs up for the application. This process ensures we have the necessary data to provide a personalized experience.

## Implementation Details

### Location
The onboarding flow is primarily implemented in the following files:
- `ContentView.swift`: Contains the main logic for determining whether to show onboarding
- `OnboardingView.swift`: The main view for the onboarding process

### State Management
The onboarding state is tracked using:
- `hasCompletedOnboarding` boolean in the User model
- UserDefaults for persistent storage of onboarding status

### Flow Structure

1. **Initial Check**
   - When the app launches, it checks if the user has completed onboarding
   - New users are directed to the onboarding flow
   - Existing users who completed onboarding see the main app interface

2. **Onboarding Screens**
   - Personal Information Collection
     - Name
     - Age
     - Gender
     - School Information
   - Preferences Setup
   - Profile Completion

3. **Completion**
   - User data is saved to Firebase
   - `hasCompletedOnboarding` is set to true
   - User is redirected to the main app interface

## User Experience

The onboarding flow is designed to be:
- Intuitive and easy to navigate
- Progressive (information collected in logical steps)
- Skippable where appropriate (optional fields)
- Visually engaging with smooth transitions

## Code Example

```swift
// ContentView.swift
struct ContentView: View {
    @State private var hasCompletedOnboarding: Bool
    
    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingView()
        } else {
            MainTabView()
        }
    }
}
```

## Future Improvements

Planned enhancements for the onboarding flow:
1. Add progress indicators
2. Implement data validation
3. Add the ability to edit information later
4. Include accessibility improvements 