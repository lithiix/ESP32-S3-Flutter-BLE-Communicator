# ESP32-S3 BLE Flutter Application

A comprehensive Flutter mobile application for controlling ESP32-S3 devices via Bluetooth Low Energy (BLE).

## Features

- **6 Specialized Controllers**: LED, Vehicle (2-wheel/4-wheel/advanced), Switches, Gamepad, Terminal, Voice Terminal
- **Voice Recognition**: Real-time speech-to-text for voice commands
- **LED Control**: RGB color picker with brightness adjustment
- **Vehicle Control**: Multiple control modes with horn/light toggle buttons
- **Gamepad**: Full gamepad interface with D-pad and action buttons
- **Real-time BLE Communication**: Bidirectional data exchange with ESP32-S3

## Getting Started

### Prerequisites

- Flutter SDK 3.6.1 or later
- Physical Android or iOS device (BLE not supported in emulators)
- ESP32-S3 device with compatible firmware

### Installation

1. **Install Dependencies**

   ```bash
   flutter pub get
   ```

2. **Configure Permissions**

   The app requires the following permissions:

   **Android** (`android/app/src/main/AndroidManifest.xml`):

   - Bluetooth (BLUETOOTH, BLUETOOTH_ADMIN, BLUETOOTH_SCAN, BLUETOOTH_CONNECT)
   - Location (ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION)
   - Microphone (RECORD_AUDIO)
   - Internet (INTERNET)

   **iOS** (`ios/Runner/Info.plist`):

   - NSBluetoothAlwaysUsageDescription
   - NSBluetoothPeripheralUsageDescription
   - NSMicrophoneUsageDescription
   - NSSpeechRecognitionUsageDescription

3. **Run the Application**

   ```bash
   flutter run
   ```

4. **Build Release APK** (Android)
   ```bash
   flutter build apk --release
   ```

## Dependencies

- `flutter_blue_plus: ^1.35.3` - BLE communication
- `permission_handler: ^11.4.0` - Runtime permissions
- `flutter_colorpicker: ^1.1.0` - Color selection
- `speech_to_text: ^7.0.0` - Voice recognition

## BLE Configuration

- **Service UUID**: `12345678-1234-1234-1234-1234567890ab`
- **Characteristic UUID**: `87654321-4321-4321-4321-ba0987654321`

## Usage

1. Launch the app and grant required permissions
2. Scan for and connect to your ESP32-S3 device
3. Select a controller from the 6 available options
4. Control your ESP32-S3 device through the chosen interface

For detailed usage instructions, see the main project README.

## Project Structure

```
lib/
├── main.dart              # Main application with all controllers
└── version_1.dart         # Legacy version (deprecated)
```

## Support

For issues and feature requests, visit: [GitHub Issues](https://github.com/senurah/ESP32-S3-Flutter-BLE-Communicator/issues)
