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
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/
```

> **Note:** `--obfuscate` strips Dart symbol names from the release binary. The `build/debug-info/` folder (gitignored) contains the symbol map needed to de-symbolicate crash reports — store it somewhere safe (e.g. a private CI artifact or secure storage).

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
| `firebase_messaging` | FCM push notification reception |
| `flutter_local_notifications` | In-app notification display |
| `google_fonts` | Custom font rendering |
| `crypto` | SHA-256 PIN hashing |
| `flutter_launcher_icons` | Generate app icons from `logo.png` |

## Push Notifications

`send_notification.js` is a Node.js script that sends an FCM push notification to all subscribed users via the `exam_updates` topic.

### Setup

```bash
npm install firebase-admin
```

### Credentials

The script requires Firebase service account credentials supplied via environment variable — **never place the key file on disk or commit it**.

**Option A (recommended):** Export the raw JSON content of your service account key:

```bash
export SERVICE_ACCOUNT_JSON='{ "type": "service_account", ... }'
node send_notification.js
```

**Option B:** Point to the key file path:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json
node send_notification.js
```

Download the service account key from **Firebase Console → Project Settings → Service accounts**. If neither variable is set, the script exits with an error.

### Usage

```bash
node send_notification.js
```

The script calculates the days remaining to the exam date and sends a reminder notification to all devices subscribed to the `exam_updates` topic.

> **Security:** `serviceAccountKey.json` is gitignored. Supply credentials only via the environment variables above — never via a local file checked into source control.

## Security

### Admin PIN

The admin PIN is stored as a SHA-256 hash in `lib/main.dart`. To change it:

1. Compute the hash of your new PIN:
   ```bash
   echo -n '<your-new-pin>' | sha256sum
   ```
2. Update the `_pinHash` constant in `_PinDialogState`.

> **Important:** Client-side PIN validation is a convenience guard only. For production, validate the PIN server-side via a Firebase Cloud Function and use Firebase Security Rules to block direct client writes to `config/examDate`.

### Firebase Security Rules

Ensure your Firestore rules restrict writes to `config/examDate` to authorised server-side operations only:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /config/examDate {
      allow read: if true;
      allow write: if false; // writes only via Cloud Function
    }
  }
}
```

### Release Build

- Enable Dart obfuscation with `--obfuscate --split-debug-info=build/debug-info/` (see Build section above).
- Configure a release signing keystore before publishing to Google Play — the current build uses debug keys as a placeholder.
- Enable [Firebase App Check](https://firebase.google.com/docs/app-check) to prevent unauthorised API access from modified clients.

## License

Private — all rights reserved.
