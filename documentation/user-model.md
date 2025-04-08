# User Model Documentation

## Overview

The User model in LengLeng represents a user of the application and stores all relevant information about their profile, preferences, and interactions within the app.

## Model Structure

### Core Properties

```swift
struct User {
    let id: String
    var username: String
    var email: String
    var profileImageURL: String?
    var hasCompletedOnboarding: Bool
    
    // Personal Information
    var firstName: String
    var lastName: String
    var gender: String?
    var age: Int?
    
    // Educational Information
    var schoolName: String?
    var grade: String?
    
    // Social Interactions
    var friends: [String]  // Array of user IDs
    var receivedCompliments: [Compliment]
    var sentCompliments: [Compliment]
}
```

### Compliment Structure

```swift
struct Compliment {
    let id: String
    let message: String
    let timestamp: Date
    let isAnonymous: Bool
    let senderId: String
}
```

## Property Descriptions

### Identification
- `id`: Unique identifier for the user (Firebase UID)
- `username`: User's chosen display name
- `email`: User's email address for authentication

### Profile
- `profileImageURL`: Optional URL to user's profile picture
- `hasCompletedOnboarding`: Boolean indicating if user has completed initial setup

### Personal Details
- `firstName`: User's first name
- `lastName`: User's last name
- `gender`: Optional gender identification
- `age`: Optional age of the user

### Educational
- `schoolName`: Name of user's school
- `grade`: User's current grade level

### Social
- `friends`: Array of user IDs representing connections
- `receivedCompliments`: Array of compliments received from others
- `sentCompliments`: Array of compliments sent to others

## Usage Examples

### Creating a New User

```swift
let newUser = User(
    id: "user123",
    username: "john_doe",
    email: "john@example.com",
    hasCompletedOnboarding: false,
    firstName: "John",
    lastName: "Doe"
)
```

### Updating User Information

```swift
func updateUserProfile(user: inout User) {
    user.hasCompletedOnboarding = true
    user.schoolName = "Springfield High"
    user.grade = "11th"
}
```

## Data Management

### Storage
- User data is stored in Firebase Firestore
- Profile images are stored in Firebase Storage
- Local caching is implemented for offline access

### Security
- Email verification required
- Age verification for certain features
- Private information is properly secured

## Best Practices

1. Always validate user input before updating the model
2. Keep sensitive information encrypted
3. Implement proper error handling for optional fields
4. Maintain data consistency across the app

## Related Components

- Authentication Service
- User Repository
- Profile View
- Friends Management
- Compliments System 