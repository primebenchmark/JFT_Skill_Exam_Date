# JFT & Skill Exam Date Countdown

A Flutter app that displays a live countdown timer to the next **JFT (Japanese-Filipino Technical) & Skill Exam** date.

## Features

- Live countdown (days, hours, minutes, seconds) to the target exam date
- 2-month progress bar showing how far along the window is
- Pulsing calendar icon with animated countdown units
- Admin PIN-protected date and time change (tap the calendar icon or the FAB)
- Real-time sync via Firebase Firestore — admin date changes reflect instantly on all users' devices
- Dark red gradient theme (Material 3)

## Screenshots

> Add screenshots here

## Getting Started

### Prerequisites

- Flutter SDK `^3.11.3`
- Dart SDK compatible with the above
- Android Studio / Xcode (for device/emulator builds)
- A Firebase project with Firestore enabled

### Firebase Setup

1. Install the FlutterFire CLI: `dart pub global activate flutterfire_cli`
2. Run `flutterfire configure --project=<your-firebase-project-id>`
3. Create a Firestore database in the [Firebase Console](https://console.firebase.google.com/) (start in test mode)
4. Create the initial document: collection `config` → document `examDate` → field `date` (timestamp)

> **Note:** `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`, and `firebase.json` are gitignored. Each developer must run `flutterfire configure` to generate their own.

### Run

```bash
flutter pub get
flutter run
```

### Build (Android)

```bash
flutter build apk --release
```

## Changing the Exam Date

Tap the **calendar icon** or the **floating action button** (bottom-right). You will be prompted for the admin PIN, then a date picker and time picker. The selected date and time are saved to Firestore and synced to all connected devices in real-time.

## Project Structure

```
lib/
└── main.dart   # Single-file app: countdown logic, UI, PIN dialog
```

## Dependencies

| Package | Purpose |
|---|---|
| `flutter` | UI framework |
| `cupertino_icons` | iOS-style icons |
| `firebase_core` | Firebase initialization |
| `cloud_firestore` | Real-time Firestore sync |
| `google_fonts` | Custom font rendering |
| `flutter_launcher_icons` | Generate app icons from `logo.png` |

## Push Notifications

`send_notification.js` is a Node.js script that sends an FCM push notification to all subscribed users via the `exam_updates` topic.

### Setup

```bash
npm install firebase-admin
```

Download your Firebase service account key from **Firebase Console → Project Settings → Service accounts** and save it as `serviceAccountKey.json` in the project root (this file is gitignored).

### Usage

```bash
node send_notification.js
```

The script calculates the days remaining to the exam date and sends a reminder notification to all devices subscribed to the `exam_updates` topic.

> **Note:** `serviceAccountKey.json` is gitignored — never commit it. Each environment needs its own key.

## License

Private — all rights reserved.
