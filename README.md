# ESP32-S3 BLE Flutter Application

A comprehensive Bluetooth Low Energy (BLE) communication system with multiple control interfaces for ESP32-S3 devices, featuring voice recognition, gamepad controls, advanced vehicle control systems, **and real-time display feedback**.

## 🎯 NEW: Display Feature

**Your ESP32 now displays everything you do on the mobile app!**

- ✅ Shows all commands on built-in OLED display (128x64)
- ✅ Real-time updates: D2:ON, LED:255,0,0,200, F (Forward), etc.
- ✅ Connection status tracking
- ✅ Command history (last 3 commands)
- ✅ Two firmware options: with display or Serial Monitor only
- ✅ **No mobile app changes required!**

📖 **Quick Start:** See [QUICK_START_DISPLAY.md](QUICK_START_DISPLAY.md)  
📖 **Full Guide:** See [DISPLAY_SETUP.md](DISPLAY_SETUP.md)  
📖 **Wiring Diagrams:** See [DISPLAY_DIAGRAMS.md](DISPLAY_DIAGRAMS.md)  
📖 **Visual Examples:** See [DISPLAY_EXAMPLES.md](DISPLAY_EXAMPLES.md)

## Features

### Core BLE Communication

- Device discovery and connection management for ESP32-S3 BLE devices
- Bidirectional data transmission between mobile app and ESP32
- Real-time notification handling and display
- **Real-time command display on ESP32 OLED screen** ⭐ NEW
- Intuitive user interface with device scanning capabilities
- Graceful connection termination and error handling
- Automatic permission handling for Bluetooth, location, and microphone services
- Direct navigation to controller selection after BLE connection

### LED Controller

- RGB color picker with real-time color selection
- Brightness slider control (0-100%)
- On/Off toggle for LED control
- Live color preview
- Smooth gradient UI design
- **Commands displayed on ESP32: LED:r,g,b,brightness** ⭐ NEW

### Vehicle Controller

Three specialized vehicle control modes:

**2-Wheel Vehicle Control**

- Directional controls: Forward, Backward, Left, Right, Stop
- Circular horn and light buttons with toggle functionality
- Press animations on all control buttons
- Real-time status indicators
- **Movement displayed on ESP32: F, B, L, R, S** ⭐ NEW

**4-Wheel Vehicle Control**

- Enhanced directional controls for four-wheel vehicles
- Circular horn and light buttons positioned beside forward control
- Toggle-based horn and light activation
- Animated button feedback
- **All actions displayed on ESP32 screen** ⭐ NEW

**Advanced Vehicle Control**

- Speed control slider (-100 to +100)
- Steering control slider (-100 to +100)
- Real-time slider value display
- Precise control for advanced maneuvers
- **Precise values shown on ESP32 display** ⭐ NEW

### Gamepad Controller

- D-Pad controls: Up, Down, Left, Right
- Action buttons: A, B, X, Y
- Shoulder buttons: L1, R1, L2, R2
- Start and Select buttons
- Press animations on all buttons
- Optimized button sizing (50x50) for comfortable use
- Scrollable interface to prevent overflow

### Terminal Controller

- Command-line interface for direct ESP32 communication
- Message history with color-coded sent/received messages
- Custom command input
- Clear terminal functionality
- Scrollable message log

### Voice Terminal Controller

- **Real-time speech recognition** using speech_to_text package
- Voice-to-command conversion
- Visual listening indicator with microphone animation
- Quick command buttons: Forward, Backward, Left, Right, Stop, LED On, LED Off, Clear
- Real-time recognized text display
- Message log with voice command history
- Microphone permission handling with user-friendly error messages

### Switches Controller

- 11 independent toggle switches (D2-D12)
- Real-time switch state management
- Visual feedback for each switch
- Bulk control capability (ALL ON / ALL OFF)
- **Each switch action displayed on ESP32: D2:ON, D5:OFF, etc.** ⭐ NEW

### User Experience

- Onboarding screen with LionBit branding and application introduction
- Custom device identification with LionBit icon for recognized devices
- Connection status indicators and real-time feedback
- Error handling with user-friendly messages and troubleshooting guidance
- Settings integration for permission management

## Screenshots

| Onboarding Screen                                                                            | Device Scanning                                                                               | Controller Selection        | Vehicle Controls               |
| -------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- | --------------------------- | ------------------------------ |
| Welcome screen with LionBit branding                                                         | Discover nearby BLE devices                                                                   | Choose from 6 controllers   | Advanced vehicle controls      |
| ![scanning](https://github.com/user-attachments/assets/f78d2c8b-cdfb-4ff1-9090-4c8d77a1085c) | ![version 1](https://github.com/user-attachments/assets/6e8ff4dd-a590-4ed6-ae28-5d9854c94951) | _6 specialized controllers_ | _LED, Vehicle, Gamepad, Voice_ |

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

   **For Basic BLE (without display):**
   - Open Tools > Manage Libraries
   - Search and install "ESP32 BLE Arduino"

   **For Display Support (recommended):**
   - Search and install "Adafruit GFX Library"
   - Search and install "Adafruit SSD1306"

4. **Choose Your Firmware**

   **Option 1: With OLED Display (Recommended)**
   - File: `esp32_sample_sketch.ino`
   - Requires: 128x64 OLED display (SSD1306, I2C)
   - Shows: Real-time commands on display
   - See: [QUICK_START_DISPLAY.md](QUICK_START_DISPLAY.md) for wiring

   **Option 2: Serial Monitor Only**
   - File: `esp32_sample_sketch_serial_monitor.ino`
   - Requires: Nothing extra
   - Shows: Formatted output in Serial Monitor

5. **Upload Firmware**
   - Open your chosen `.ino` file from the `esp32_ble_firmware/` directory
   - Select your ESP32-S3 board from Tools > Board
   - Connect your ESP32-S3 via USB
   - Click Upload
   - Open Serial Monitor (115200 baud) to verify BLE advertising status
   - If using display: Watch display show "Waiting for connection..."

### Display Setup (Optional but Recommended)

See complete guides:

- **Quick Start:** [QUICK_START_DISPLAY.md](QUICK_START_DISPLAY.md)
- **Wiring Diagrams:** [DISPLAY_DIAGRAMS.md](DISPLAY_DIAGRAMS.md)
- **Full Setup:** [DISPLAY_SETUP.md](DISPLAY_SETUP.md)

**Quick Wiring:**

```
OLED Display → ESP32-S3
VCC → 3.3V
GND → GND
SDA → GPIO 21
SCL → GPIO 22
```

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
   - `ACCESS_COARSE_LOCATION`
   - `RECORD_AUDIO` (for voice terminal)
   - `INTERNET` (for speech recognition)

   **iOS**: Add required keys to `ios/Runner/Info.plist`:
   - `NSBluetoothAlwaysUsageDescription`
   - `NSBluetoothPeripheralUsageDescription`
   - `NSMicrophoneUsageDescription` (for voice terminal)
   - `NSSpeechRecognitionUsageDescription` (for voice terminal)

5. **Deploy Application**

   ```bash
   flutter run
   ```

## Usage

### Getting Started

1. Launch the application to see the onboarding screen
2. Tap "Get Started" to proceed to the BLE scanning interface

### Connecting to ESP32-S3

1. Power on your ESP32-S3 device
2. The app will automatically start scanning for nearby BLE devices
3. Select your device from the discovered devices list (LionBit_BLE devices will show with a custom icon)
4. Wait for connection and service discovery (loading screen will appear)
5. Once connected, you'll be directed to the Controller Selection screen

### Choosing a Controller

Select from 6 specialized control interfaces:

1. **LED Controller** - RGB color and brightness control
2. **Vehicle Controller** - Choose from 2-wheel, 4-wheel, or advanced controls
3. **Switches** - 8 independent toggle switches
4. **Gamepad** - Full gamepad interface with D-pad and action buttons
5. **Terminal** - Command-line interface
6. **Voice Terminal** - Voice-controlled commands

### Using LED Controller

1. Tap the color picker to select your desired RGB color
2. Adjust brightness using the slider (0-100%)
3. Toggle the LED on/off using the power button
4. Colors are sent to ESP32 in real-time

### Using Vehicle Controllers

**2-Wheel / 4-Wheel Mode:**

1. Use directional arrows to control movement (Forward, Backward, Left, Right)
2. Press and hold buttons for continuous movement
3. Tap the circular horn button (left) to toggle horn ON/OFF
4. Tap the circular light button (right) to toggle lights ON/OFF
5. Tap Stop to halt all movement
6. All buttons animate on press for tactile feedback

**Advanced Mode:**

1. Use the speed slider to control velocity (-100 to +100)
2. Use the steering slider to control direction (-100 to +100)
3. Drag sliders for precise control
4. Values update in real-time

### Using Gamepad Controller

1. Use D-pad for directional input (Up, Down, Left, Right)
2. Press action buttons (A, B, X, Y) for functions
3. Use shoulder buttons (L1, R1, L2, R2) for additional controls
4. Start and Select buttons for menu functions
5. All buttons provide visual press feedback
6. Scroll for access to all controls

### Using Terminal Controller

1. Type commands in the input field
2. Press send to transmit to ESP32
3. View message history in the terminal log
4. Clear terminal using the delete icon
5. Sent messages appear in green, received in blue

### Using Voice Terminal Controller

1. **Grant Microphone Permission**: On first use, allow microphone access when prompted
2. **Voice Control**: Tap and hold the microphone button to speak
3. **View Recognition**: Watch your spoken words appear in real-time
4. **Auto-Send**: Commands are automatically sent when you finish speaking
5. **Quick Commands**: Use preset buttons for instant commands:
   - Forward, Backward, Left, Right, Stop
   - LED On, LED Off
   - Clear (clears message log)
6. **Message Log**: View all sent voice commands in the terminal-style log

### Using Switches Controller

1. Toggle any of the 8 switches ON/OFF
2. Each switch sends its state to ESP32
3. Visual feedback shows current state
4. Control multiple switches independently

### Disconnecting

Use the back button to return to controller selection, or disconnect from the BLE scanning screen to terminate the connection safely.

## Troubleshooting

| Issue                             | Resolution                                                                                                                                                                                         |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ESP32 not detected during scan    | Verify ESP32 is powered and advertising. Check Serial Monitor output. Restart device if necessary.                                                                                                 |
| Application crashes on launch     | Verify all Flutter dependencies are properly installed. Run `flutter doctor` to check configuration.                                                                                               |
| Permission errors on Android      | The app will prompt for permissions on first launch. If denied, manually grant Bluetooth, Location, and Microphone permissions in device settings or use the "Open Settings" option in the dialog. |
| BLE scan frequency errors         | Implement scan throttling with minimum 10-second intervals between scans.                                                                                                                          |
| Cannot send commands              | Ensure the device is properly connected and services are discovered. Check for the green "Device ready" snackbar message. Verify UUIDs match between app and ESP32 firmware.                       |
| Voice recognition not available   | Ensure microphone permission is granted. Rebuild the app after updating permissions in AndroidManifest.xml and Info.plist. Check device speech recognition support.                                |
| Voice commands not recognized     | Speak clearly and wait for the listening indicator. Ensure a stable internet connection for speech processing. Check microphone hardware.                                                          |
| Controller buttons not responding | Verify the ESP32 firmware is programmed to handle the specific commands. Check Serial Monitor for received commands.                                                                               |
| Gamepad buttons overflow          | Scroll the gamepad interface to access all buttons. All buttons are within a scrollable container.                                                                                                 |
| LED colors not changing           | Verify ESP32 firmware supports RGB commands. Check that LED hardware is connected properly.                                                                                                        |

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
- Feature enhancements (additional controllers, custom command macros, etc.)
- UI/UX improvements
- Voice recognition accuracy improvements
- Documentation improvements
- Support for additional BLE devices
- Multi-language support

## Technical Details

### BLE Configuration

The application uses the following UUIDs (ensure your ESP32 firmware matches):

- **Service UUID**: `12345678-1234-1234-1234-1234567890ab`
- **Characteristic UUID**: `87654321-4321-4321-4321-ba0987654321`

### Control Commands

The controllers send various command formats:

**Vehicle Controllers:**

- `F` - Forward
- `B` - Backward
- `L` - Left
- `R` - Right
- `S` - Stop
- `HORN:ON` / `HORN:OFF` - Horn control
- `LIGHT:ON` / `LIGHT:OFF` - Light control
- `SPEED:<value>` - Speed control (-100 to 100)
- `STEER:<value>` - Steering control (-100 to 100)

**LED Controller:**

- `RGB:<r>,<g>,<b>` - Set RGB color (0-255 each)
- `BRIGHTNESS:<value>` - Set brightness (0-100)
- `LED:ON` / `LED:OFF` - LED power control

**Gamepad Controller:**

- `UP`, `DOWN`, `LEFT`, `RIGHT` - D-pad directions
- `A`, `B`, `X`, `Y` - Action buttons
- `L1`, `R1`, `L2`, `R2` - Shoulder buttons
- `START`, `SELECT` - Menu buttons

**Switches Controller:**

- `SWITCH<n>:ON` / `SWITCH<n>:OFF` - Individual switch control (n = 1-8)

**Terminal/Voice Terminal:**

- Custom text commands as entered/spoken

### Dependencies

Key Flutter packages used:

- `flutter_blue_plus: ^1.35.3` - BLE communication
- `permission_handler: ^11.4.0` - Runtime permissions management
- `flutter_colorpicker: ^1.1.0` - Color selection for LED controller
- `speech_to_text: ^7.0.0` - Voice recognition for voice terminal

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
