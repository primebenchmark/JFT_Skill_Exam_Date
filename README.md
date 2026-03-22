# JFT & Skill Exam Date Countdown

A Flutter app that displays a live countdown timer to the next **JFT (Japanese-Filipino Technical) & Skill Exam** date.

## Features

- Live countdown (days, hours, minutes, seconds) to the target exam date
- 2-month progress bar showing how far along the window is
- Pulsing calendar icon with animated countdown units
- Admin PIN-protected date change (tap the calendar icon or the FAB)
- Dark red gradient theme (Material 3)

## Screenshots

> Add screenshots here

## Getting Started

### Prerequisites

- Flutter SDK `^3.11.3`
- Dart SDK compatible with the above
- Android Studio / Xcode (for device/emulator builds)

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

Tap the **calendar icon** or the **floating action button** (bottom-right). You will be prompted for the admin PIN to proceed.

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
| `flutter_launcher_icons` | Generate app icons from `logo.png` |

## License

Private — all rights reserved.
