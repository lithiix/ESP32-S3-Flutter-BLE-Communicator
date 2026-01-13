# ESP32-S3 BLE Flutter Application

A Bluetooth Low Energy (BLE) communication system demonstrating bidirectional data exchange between an ESP32-S3 development board and a Flutter mobile application.

## Features

### Core BLE Communication

- Device discovery and connection management for ESP32-S3 BLE devices
- Bidirectional data transmission between mobile app and ESP32
- Real-time notification handling and display
- Intuitive user interface with device scanning capabilities
- Graceful connection termination and error handling
- Automatic permission handling for Bluetooth and location services

### Chat Interface

- Real-time bidirectional chat communication with ESP32 devices
- Message history display with visual differentiation between sent and received messages
- Chat bubble UI with color-coded messages (blue for sent, gray for received)
- Clear chat functionality to reset conversation history
- Message input with send button for easy text transmission

### Car Control Interface

- Dedicated car control screen with joystick-style controls
- Directional commands: Forward, Backward, Left, Right, and Stop
- Touch-responsive control buttons with visual feedback
- Real-time direction status display
- Gradient UI design with LionBit branding
- Automatic command sending on button press/release

### User Experience

- Onboarding screen with LionBit branding and application introduction
- Custom device identification with LionBit icon for recognized devices
- Connection status indicators and real-time feedback
- Error handling with user-friendly messages and troubleshooting guidance
- Settings integration for permission management

## Screenshots

| Onboarding Screen                                                                            | Device Scanning                                                                               | Chat Interface                 | Car Control                     |
| -------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- | ------------------------------ | ------------------------------- |
| Welcome screen with LionBit branding                                                         | Discover nearby BLE devices                                                                   | Real-time messaging            | Joystick-style controls         |
| ![scanning](https://github.com/user-attachments/assets/f78d2c8b-cdfb-4ff1-9090-4c8d77a1085c) | ![version 1](https://github.com/user-attachments/assets/6e8ff4dd-a590-4ed6-ae28-5d9854c94951) | _Chat UI with message bubbles_ | _Directional control interface_ |

## Project Structure

```
ESP32-S3-BLE-App/
├── flutter_app/              # Flutter mobile application
├── esp32_ble_firmware/       # ESP32 Arduino firmware
└── README.md                 # Project documentation
```

## Getting Started

### Prerequisites

- Arduino IDE 1.8.x or later
- Flutter SDK 3.0 or later
- ESP32-S3 development board
- Physical Android or iOS device (BLE not supported in emulators)

### ESP32-S3 Firmware Setup

1. **Install Arduino IDE**

   Download from the [official Arduino website](https://www.arduino.cc/en/software).

2. **Configure ESP32 Board Support**

   - Navigate to File > Preferences
   - Add the following URL to Additional Boards Manager URLs:
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Open Tools > Board > Boards Manager
   - Search for "ESP32" and install "ESP32 by Espressif Systems"

3. **Install Required Libraries**

   - Open Tools > Manage Libraries
   - Search and install "ESP32 BLE Arduino"

4. **Upload Firmware**

   - Open `esp32_ble_firmware.ino` from the `esp32_ble_firmware/` directory
   - Select your ESP32-S3 board from Tools > Board
   - Connect your ESP32-S3 via USB
   - Click Upload
   - Open Serial Monitor (115200 baud) to verify BLE advertising status

### Flutter Application Setup

1. **Install Flutter**

   Follow the [official Flutter installation guide](https://flutter.dev/docs/get-started/install) for your operating system.

2. **Clone Repository**

   ```bash
   https://github.com/senurah/ESP32-S3-Flutter-BLE-Communicator.git
   ```

3. **Install Dependencies**

   ```bash
   flutter pub get
   ```

4. **Configure Permissions**

   **Android**: Ensure the following permissions are declared in `android/app/src/main/AndroidManifest.xml`:

   - `BLUETOOTH`
   - `BLUETOOTH_ADMIN`
   - `BLUETOOTH_SCAN`
   - `BLUETOOTH_CONNECT`
   - `ACCESS_FINE_LOCATION`

   **iOS**: Add required keys to `ios/Runner/Info.plist`:

   - `NSBluetoothAlwaysUsageDescription`
   - `NSBluetoothPeripheralUsageDescription`

5. **Deploy Application**

   ```bash
   flutter run
   ```

## Usage

### Getting Started

1. Launch the application to see the onboarding screen
2. Tap "Get Started" to proceed to the main BLE interface

### Connecting to ESP32-S3

1. Power on your ESP32-S3 device
2. The app will automatically start scanning for nearby BLE devices
3. Select your device from the discovered devices list (LionBit_BLE devices will show with a custom icon)
4. Wait for the connection to establish and services to be discovered

### Chat Mode

1. Once connected, the chat interface will appear
2. Enter your message in the text input field at the bottom
3. Tap the send button or press Enter to transmit
4. Messages you send appear in blue bubbles on the right
5. Messages received from ESP32 appear in gray bubbles on the left
6. Use "Clear Chat" button to reset the conversation history

### Car Control Mode

1. From the chat interface, tap the "Car Control" button
2. Use the joystick-style interface to control your device:
   - **Forward**: Tap and hold the up arrow
   - **Backward**: Tap and hold the down arrow
   - **Left**: Tap and hold the left arrow
   - **Right**: Tap and hold the right arrow
   - **Stop**: Release any directional button or tap the stop button
3. The current direction is displayed at the top
4. Commands are automatically sent while buttons are pressed

### Disconnecting

Press the "Disconnect" button in the chat interface to terminate the BLE connection safely and return to the device scanning screen.

## Troubleshooting

| Issue                          | Resolution                                                                                                                                                                                       |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| ESP32 not detected during scan | Verify ESP32 is powered and advertising. Check Serial Monitor output. Restart device if necessary.                                                                                               |
| Application crashes on launch  | Verify all Flutter dependencies are properly installed. Run `flutter doctor` to check configuration.                                                                                             |
| Permission errors on Android   | The app will prompt for permissions on first launch. If denied, manually grant Bluetooth and Location permissions in device settings or use the "Open Settings" option in the permission dialog. |
| BLE scan frequency errors      | Implement scan throttling with minimum 10-second intervals between scans.                                                                                                                        |
| Cannot send messages           | Ensure the device is properly connected and services are discovered. Check for the green "Device ready" snackbar message. Verify UUIDs match between app and ESP32 firmware.                     |
| Car control not responding     | Verify the ESP32 firmware is programmed to handle directional commands (F, B, L, R, S). Check Serial Monitor for received commands.                                                              |
| Chat messages not appearing    | Ensure BLE notifications are enabled on the characteristic. Check that the ESP32 is sending data correctly.                                                                                      |

## Contributing

Contributions are welcome and encouraged. To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

Areas for contribution include:

- Bug reports and fixes
- Performance optimizations
- Feature enhancements (speed control, additional car functions, etc.)
- UI/UX improvements
- Documentation improvements
- Support for additional BLE devices

## Technical Details

### BLE Configuration

The application uses the following UUIDs (ensure your ESP32 firmware matches):

- **Service UUID**: `12345678-1234-1234-1234-1234567890ab`
- **Characteristic UUID**: `87654321-4321-4321-4321-ba0987654321`

### Control Commands

The car control interface sends single-character commands:

- `F` - Forward
- `B` - Backward
- `L` - Left
- `R` - Right
- `S` - Stop

### Dependencies

Key Flutter packages used:

- `flutter_blue_plus`: BLE communication
- `permission_handler`: Runtime permissions management

## License

This project is open source. See the LICENSE file for details.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Support

For bug reports, feature requests, or general questions:

- Open an issue on [GitHub Issues](https://github.com/senurah/ESP32-S3-BLE-App/issues)
- Contact the maintainer: [GitHub - senurah](https://github.com/senurah)

## Acknowledgments

Built with ESP32 Arduino Core and Flutter's flutter_blue_plus package.
