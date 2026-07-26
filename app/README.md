# arinanoX Companion App

Flutter-based Android companion app for arinanoX.

## Architecture

```
lib/
├── main.dart                    # Entry point + Provider setup
├── state/app_state.dart         # Central state (ChangeNotifier)
├── services/shell_bridge.dart   # MethodChannel → Kotlin shell executor
├── theme/arinanox_theme.dart    # Design system (ATM from DroidDesk)
└── screens/
    ├── home_screen.dart         # Dashboard: status, actions, system info
    └── terminal_screen.dart     # Terminal bottom sheet
```

## Setup

```bash
# 1. Install Flutter SDK
# https://docs.flutter.dev/get-started/install

# 2. Get dependencies
cd app
flutter pub get

# 3. Run on device
flutter run
```

## Build

```bash
# Debug APK
flutter build apk --debug

# Release APK  
flutter build apk --release
```

## GitHub Actions

Manual trigger only: **Actions → Build arinanoX APK → Run workflow**

Artifacts are available for 30 days after build.

## Key Differences from DroidDesk (ATM reference)

| Feature | DroidDesk | arinanoX App |
|---------|-----------|--------------|
| Setup wizard | Welcome → Distro → DE → Install | N/A (handled by `bootstrap.sh`) |
| Session management | Start/stop chroot or native | Start/stop proot via `arinanox` CLI |
| Display server | Embedded X11 (Phase 2 goal) | External Termux:X11 APK |
| State complexity | ~700 lines (root + native paths) | ~200 lines (proot only) |
| Terminal | Native + debian proot shell | Single proot shell |
| App catalog | Optional app installer | N/A (handled by `patch.sh`) |
