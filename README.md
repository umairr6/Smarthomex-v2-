# SmartHomeX

> Smart Control. Simplified.

SmartHomeX is a Flutter-based smart home control application designed to control electrical appliances through an ESP32 and a 4-channel relay module over a local Wi-Fi network.

The first version (V1) focuses on controlling a single room.

---

## 🚀 Version

**Current Version:** 1.0.0  
**Platform:** Flutter  
**Hardware:** ESP32 + 4-Channel Relay  
**Communication:** Local Wi-Fi / HTTP

---

# 📱 V1 Features

- Single-room smart home control
- ESP32 connection over local Wi-Fi
- 4-channel relay control
- Real-time relay status
- ESP32 online/offline detection
- Manual ESP32 IP configuration
- Local device configuration
- Rename switches
- Modern dark-themed UI

---

# 🏠 System Architecture

```text
                  SmartHomeX
                Flutter App
                     │
                     │ HTTP
                     │
                Local Wi-Fi
                     │
                     ▼
              ┌───────────────┐
              │     ESP32     │
              │  HTTP Server  │
              └───────┬───────┘
                      │
                      ▼
              ┌───────────────┐
              │ 4-Channel     │
              │ Relay Module  │
              └─┬───┬───┬───┬─┘
                │   │   │   │
                ▼   ▼   ▼   ▼
               R1  R2  R3  R4
````

---

# 🛠 Hardware

## Required Components

* ESP32 development board
* 4-channel relay module
* Wi-Fi router or mobile hotspot
* Appropriate power supply
* Electrical loads/appliances

### Example

```text
Relay 1 → Light 1
Relay 2 → Light 2
Relay 3 → Fan
Relay 4 → Socket
```

---

# 🔌 ESP32 Pin Configuration

Default configuration:

| Relay   | ESP32 GPIO |
| ------- | ---------- |
| Relay 1 | GPIO 23    |
| Relay 2 | GPIO 22    |
| Relay 3 | GPIO 21    |
| Relay 4 | GPIO 19    |

The pins can be changed in the ESP32 firmware.

---

# 📡 Communication

SmartHomeX V1 uses HTTP over the local network.

## ESP32 Status

```http
GET /status
```

Example:

```json
{
  "status": "online",
  "relay1": false,
  "relay2": false,
  "relay3": false,
  "relay4": false
}
```

---

## Relay Control

### Relay 1

```http
GET /relay1/on
GET /relay1/off
```

### Relay 2

```http
GET /relay2/on
GET /relay2/off
```

### Relay 3

```http
GET /relay3/on
GET /relay3/off
```

### Relay 4

```http
GET /relay4/on
GET /relay4/off
```

---

# 📂 Flutter Project Structure

```text
lib/
│
├── main.dart
│
├── core/
│   ├── colors.dart
│   ├── constants.dart
│   └── routes.dart
│
├── models/
│   ├── device_model.dart
│   └── relay_model.dart
│
├── providers/
│   └── device_provider.dart
│
├── services/
│   ├── api_service.dart
│   ├── storage_service.dart
│   └── wifi_service.dart
│
├── screens/
│   ├── splash/
│   │   └── splash_screen.dart
│   │
│   ├── setup/
│   │   └── setup_screen.dart
│   │
│   ├── home/
│   │   └── home_screen.dart
│   │
│   └── settings/
│       └── settings_screen.dart
│
├── widgets/
│   ├── smart_switch.dart
│   ├── room_card.dart
│   ├── custom_button.dart
│   └── status_indicator.dart
│
└── utils/
    └── validators.dart
```

---

# 🧠 Application Architecture

SmartHomeX follows a simple layered architecture.

```text
UI
 │
 ▼
Provider
 │
 ▼
Services
 │
 ▼
ESP32 API
```

### UI Layer

Responsible for:

* Screens
* Buttons
* Switches
* Animations
* User interaction

### Provider Layer

Responsible for:

* Device state
* Relay state
* Online/offline state
* Updating UI

### Service Layer

Responsible for:

* HTTP communication
* Wi-Fi operations
* Local storage

### Model Layer

Responsible for representing:

* ESP32 devices
* Relays

---

# 📦 Flutter Dependencies

Current dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter

  provider: ^6.1.5
  http: ^1.5.0
  shared_preferences: ^2.5.3
  google_fonts: ^6.3.1
  flutter_svg: ^2.2.0
```

Install dependencies:

```bash
flutter pub get
```

---

# 💻 Running the Flutter App

Clone/open the project and run:

```bash
flutter pub get
```

Then:

```bash
flutter run
```

For Windows:

```bash
flutter run -d windows
```

For Android:

```bash
flutter run -d android
```

---

# 🔧 ESP32 Setup

## 1. Install Arduino IDE

Install Arduino IDE and configure ESP32 board support.

## 2. Configure Wi-Fi

In the ESP32 firmware:

```cpp
const char* WIFI_SSID = "IBN UMAIR";
const char* WIFI_PASSWORD = "12344321";
```

Replace these with your Wi-Fi credentials.

## 3. Upload Firmware

Connect the ESP32 to your computer and upload the firmware.

## 4. Open Serial Monitor

Set the baud rate to:

```text
115200
```

The ESP32 should display:

```text
SmartHomeX ESP32
----------------

Connecting to Wi-Fi....

Wi-Fi connected!

ESP32 IP Address: 192.168.1.100

HTTP server started.

SmartHomeX is ready!
```

---

# 🧪 Testing the ESP32

Once the ESP32 is connected to Wi-Fi, open a browser on a device connected to the same network.

Replace the IP address with your ESP32 IP.

```text
http://192.168.1.100/status
```

Expected response:

```json
{
  "status": "online",
  "relay1": false,
  "relay2": false,
  "relay3": false,
  "relay4": false
}
```

Test Relay 1:

```text
http://192.168.1.100/relay1/on
```

Turn it off:

```text
http://192.168.1.100/relay1/off
```

---

# ⚠️ Safety

The relay module can be used to control high-voltage electrical loads.

**Do not work directly with mains electricity unless you are qualified to do so.**

For development and testing, use a safe low-voltage load whenever possible.

Ensure:

* Correct relay wiring
* Correct power supply
* Proper insulation
* Proper enclosure
* Appropriate electrical protection

---

# 🔐 Security

V1 is designed for **local-network development and testing**.

The current HTTP API does not include authentication or encryption.

Do not expose the ESP32 HTTP server directly to the public internet.

Future versions should introduce appropriate authentication and secure communication before remote/cloud control is implemented.

---

# 🗺 Roadmap

## V1 — Single Room

* [x] Flutter project
* [x] Splash screen
* [x] Device setup screen
* [x] Device model
* [x] Relay model
* [x] Device provider
* [x] ESP32 HTTP API
* [ ] Flutter ↔ ESP32 connection
* [ ] Home dashboard
* [ ] Relay controls
* [ ] Live status
* [ ] Local storage
* [ ] Settings

---

## V2 — Multiple Rooms

Planned:

```text
Home
│
├── Living Room
│   └── ESP32
│
├── Bedroom
│   └── ESP32
│
├── Kitchen
│   └── ESP32
│
└── Office
    └── ESP32
```

Features:

* Multiple ESP32 devices
* Multiple rooms
* Device management
* Room management
* Groups

---

## V3 — Automation

Planned:

* Timers
* Schedules
* Scenes
* Automation rules
* Sunrise/sunset actions
* Device groups

Example:

```text
Every day at 7:00 PM

→ Turn Living Room Light ON
→ Turn Bedroom Light ON
```

---

## V4 — Voice & Remote Control

Planned:

* Voice commands
* Alexa integration
* Google Assistant integration
* Remote access
* Push notifications
* Cloud synchronization

---

## V5 — Advanced Smart Home

Future possibilities:

* Energy monitoring
* Sensors
* Temperature monitoring
* Motion detection
* Door/window sensors
* AI-based automation
* Usage analytics
* Smart routines

---

# 📊 Future Architecture

```text
                    SmartHomeX
                        │
                ┌───────┴────────┐
                │                │
             Flutter           Cloud
                │                │
                └───────┬────────┘
                        │
                    Home Hub
                        │
          ┌─────────────┼─────────────┐
          │             │             │
        ESP32         ESP32         ESP32
          │             │             │
       Bedroom       Kitchen       Living Room
```

---

# 📜 License

This project is currently under development.

License information will be added before public release.

---

# 👨‍💻 Project Status

**SmartHomeX is currently in active development.**

Current focus:

> Establishing reliable local communication between the Flutter application and ESP32 hardware.

````

### Save it as

```text
SmartHomeX/
└── README.md
````

This gives us a proper project reference as we continue. **Next, I'd build the ESP32 firmware folder/documentation alongside the Flutter project, then we'll test `/status` before touching the Flutter connection logic.**
