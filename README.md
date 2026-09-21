# SmartHomeX V2

SmartHomeX V2 is a Flutter smart-home control app with account-based access, multi-home and multi-room management, ESP32 pairing, and MQTT-ready device control.

## What's in V2

- Supabase authentication: sign up, sign in, and sign out
- Optional in-app lock with PIN setup and verification
- Multiple homes, each with multiple rooms
- Create, rename, and delete homes and rooms
- Pair, view, and unpair ESP32 devices per room
- Room-level device controls and relay models
- Timers and schedules screens with supporting models
- MQTT service and bundled EMQX CA certificate for secure broker connections
- Local HTTP, Wi-Fi, device, and storage service layers
- Dark SmartHomeX theme, animated background, and cinematic intro video
- Flutter targets for Android, iOS, Windows, macOS, and Linux

## Project Structure

```text
SmartHomeX/
├── assets/
│   ├── certificates/          # EMQX TLS certificate
│   └── videos/                # Splash and dashboard video assets
├── lib/
│   ├── core/                  # Theme, colors, routes, and shared background
│   ├── models/                # Device, relay, timer, and schedule models
│   ├── providers/             # Application state providers
│   ├── screens/
│   │   ├── app_lock/          # PIN lock flow
│   │   ├── auth/              # Sign-in and sign-up flow
│   │   ├── home/              # Home dashboard and room controls
│   │   ├── schedules/         # Schedule management UI
│   │   ├── setup/             # ESP32 setup and pairing
│   │   ├── splash/            # App launch screen
│   │   └── timers/            # Timer management UI
│   ├── services/              # Supabase, MQTT, HTTP, Wi-Fi, and local storage
│   ├── utils/                 # Validation helpers
│   ├── widgets/               # Reusable UI components
│   └── main.dart              # App entry point and initialization
├── android/                   # Android platform project
├── ios/                       # iOS platform project
├── linux/                     # Linux platform project
├── macos/                     # macOS platform project
├── windows/                   # Windows platform project
├── test/                      # Flutter tests
└── pubspec.yaml               # Dependencies and bundled assets
```

## Main Technologies

- Flutter and Dart
- Supabase
- MQTT
- ESP32 smart-home devices
- Media Kit video playback

## Run Locally

```bash
flutter pub get
flutter run
```

> SmartHomeX V2 is in active development.
