# Widers Mobile Chat Application

Mobile chat application for Widers merchants and employees to manage WhatsApp customer conversations on the go.

## Overview

Widers is an official Meta-approved WhatsApp Business Cloud API provider. This project delivers a frontend mobile app connected to the existing Laravel backend APIs.

The app focuses on:
- Receiving WhatsApp messages from customers
- Replying to conversations
- Getting real-time push notifications
- Managing conversations from mobile devices

## MVP Features

- Authentication (connected to existing Widers login system)
- Conversations list (customer name, last message, time, unread count)
- Chat screen (send/receive text and images)
- Close conversation
- Internal notes (only visible to team members)
- Push notifications

## Technical Scope

- Frontend mobile app only (backend is already available in Laravel)
- Real-time updates through Firebase or WebSockets
- Target platforms:
  - Android 8+
  - iOS

## Current Repository Structure

- `android/` - Android application project
- `ios/` - iOS application project
- `Widers API updated.postman_collection.json` - API collection for backend integration

## API Integration Notes

- Use the existing Laravel APIs for authentication, conversation listing, messaging, and notes.
- Ensure all API calls include proper authentication tokens from the Widers platform.
- Align request/response handling with the Postman collection in this repository.

## Suggested Next Implementation Steps

1. Configure environment variables for API base URL and keys.
2. Implement auth flow and secure token storage.
3. Build conversations list UI with unread badge and timestamps.
4. Build chat details UI with text/image messaging.
5. Add internal notes and close conversation actions.
6. Integrate push notifications and real-time updates.
7. Test on Android 8+ and iOS physical devices.

## Getting Started

Because this repository includes platform-specific projects, run setup and build commands from each platform folder as needed.

- Android: open `android/` in Android Studio or use Gradle CLI.
- iOS: open `ios/` in Xcode and install pods if required.

## License

Internal project for Widers.
