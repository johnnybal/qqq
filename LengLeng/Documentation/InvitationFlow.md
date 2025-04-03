# LengLeng Invitation System

## Overview

The invitation system allows users to invite their friends to join LengLeng. Users can earn rewards for successful invitations and track the status of their invites.

## Components

### Models

- **ContactToInvite**: Represents a contact that can be invited
  - `id`: Unique identifier
  - `name`: Contact's name
  - `phoneNumber`: Contact's phone number
  - `school`: Optional school information

- **Invitation**: Represents an invitation
  - `id`: Unique identifier
  - `senderId`: ID of the user sending the invitation
  - `recipientPhone`: Phone number of the recipient
  - `recipientName`: Name of the recipient
  - `message`: Custom message or generated message
  - `messageVariant`: Type of message (standard or time-based)
  - `createdAt`: When the invitation was created
  - `expiresAt`: When the invitation expires (24 hours after creation)
  - `status`: Current status (sent, clicked, installed, expired)
  - `trackingData`: Data about the invitation's progress

### Services

- **InvitationService**: Manages the invitation process
  - Sending invitations
  - Tracking invitation status
  - Managing available invites
  - Awarding rewards

- **MessagingService**: Handles sending SMS invitations
  - Sending text messages
  - Handling message composition
  - Managing message UI

### Views

- **HomeView**: Main view with invite button and recent invites
- **InviteFriendsView**: Contact picker and invitation sending
- **InviteHistoryView**: Detailed history of all invitations

## Invitation Flow

1. **User Initiates Invite**
   - User taps "Invite Friends" button
   - InviteFriendsView is presented

2. **Contact Selection**
   - User selects contacts from their address book
   - User can optionally add a custom message

3. **Sending Invitation**
   - System checks if user has available invites
   - Generates a unique invite link
   - Creates invitation record in Firebase
   - Sends SMS to selected contacts
   - Updates user's available invites count

4. **Tracking**
   - System tracks when invitation is clicked
   - System tracks when app is installed
   - System can send reminders if invitation is not acted upon

5. **Rewards**
   - User earns 5 bonus invites for each successful installation
   - User can earn invites for maintaining streaks
   - Premium users receive additional invites

## Firebase Collections

- **users**
  - `availableInvites`: Number of invites user has remaining

- **invitations**
  - Contains all invitation records
  - Tracks status and analytics

## Error Handling

The system handles various error cases:
- No invites remaining
- Invalid contact information
- Failed message sending
- Firebase errors
- Authentication errors

## Analytics

The system tracks:
- Invitation send rate
- Click-through rate
- Installation rate
- Reminder effectiveness
- Reward distribution 