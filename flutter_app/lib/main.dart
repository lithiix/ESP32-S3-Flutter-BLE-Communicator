import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/lionbit_car.png',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 30),
            const Text(
              "LionBit BLE Communicator",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Connect and communicate with your ESP32 devices via Bluetooth Low Energy",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BLEHomeScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                "Get Started",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BLEHomeScreen extends StatefulWidget {
  const BLEHomeScreen({super.key});

  @override
  State<BLEHomeScreen> createState() => _BLEHomeScreenState();
}

class _BLEHomeScreenState extends State<BLEHomeScreen> {
  // UUIDs must match your ESP32 firmware
  static const String SERVICE_UUID = "12345678-1234-1234-1234-1234567890ab";
  static const String CHARACTERISTIC_UUID =
      "87654321-4321-4321-4321-ba0987654321";

  List<BluetoothDevice> scannedDevices = [];
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? targetCharacteristic;
  bool isDiscoveringServices = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  /// Initialize Bluetooth and request permissions
  Future<void> _initBluetooth() async {
    await requestPermissions();
    startScan();
  }

  /// Request necessary permissions for Bluetooth
  Future<void> requestPermissions() async {
    // Request all permissions and check if granted
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Check if all permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      print("❌ Some permissions were denied:");
      statuses.forEach((permission, status) {
        print("  $permission: $status");
      });

      // Show dialog to user
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
                'Bluetooth and Location permissions are required to scan for BLE devices. '
                'Please grant all permissions in the app settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    } else {
      print("✅ All Bluetooth permissions granted");
    }
  }

  /// Start scanning for BLE devices
  void startScan() async {
    scannedDevices.clear();
    setState(() {});

    // Check if Bluetooth is available
    if (await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }

    // Check if Bluetooth is turned on
    var adapterState = await FlutterBluePlus.adapterState.first;
    print("Bluetooth adapter state: $adapterState");
    if (adapterState != BluetoothAdapterState.on) {
      print("Please turn on Bluetooth");
      return;
    }

    print("Starting BLE scan...");
    await FlutterBluePlus.stopScan();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      print("Scan found ${results.length} devices");
      for (ScanResult result in results) {
        String deviceName = result.device.platformName;
        print("Found device: $deviceName (${result.device.remoteId})");

        // Show all devices with names (remove ESP32 filter temporarily for debugging)
        if (deviceName.isNotEmpty && !scannedDevices.contains(result.device)) {
          print("Adding device: $deviceName");
          setState(() {
            scannedDevices.add(result.device);
          });
        }
      }
    });

    Future.delayed(const Duration(seconds: 15), () {
      print("Scan completed. Found ${scannedDevices.length} devices");
      FlutterBluePlus.stopScan();
    });
  }

  /// Connect to a BLE device
  void connectToDevice(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    await device.connect();
    setState(() {
      connectedDevice = device;
      isDiscoveringServices = true;
    });

    discoverServices(device);
  }

  /// Discover services & characteristics
  void discoverServices(BluetoothDevice device) async {
    try {
      print("=== Starting Service Discovery ===");
      print("Looking for Service UUID: $SERVICE_UUID");
      print("Looking for Characteristic UUID: $CHARACTERISTIC_UUID");

      List<BluetoothService> services = await device.discoverServices();
      print("Found ${services.length} services");

      // Print all services and characteristics for debugging
      for (var service in services) {
        print("\n--- Service: ${service.uuid} ---");
        for (var char in service.characteristics) {
          print("  Characteristic: ${char.uuid}");
          print("    Read: ${char.properties.read}");
          print("    Write: ${char.properties.write}");
          print(
              "    WriteWithoutResponse: ${char.properties.writeWithoutResponse}");
          print("    Notify: ${char.properties.notify}");
        }
      }

      print("\n=== Searching for Target Service ===");
      for (var service in services) {
        print(
            "Comparing: ${service.uuid.toString().toLowerCase()} with ${SERVICE_UUID.toLowerCase()}");

        // Look for our specific service
        if (service.uuid.toString().toLowerCase() ==
            SERVICE_UUID.toLowerCase()) {
          print("✓ Found target service: ${service.uuid}");

          for (var characteristic in service.characteristics) {
            print(
                "  Comparing char: ${characteristic.uuid.toString().toLowerCase()} with ${CHARACTERISTIC_UUID.toLowerCase()}");

            // Match our specific characteristic
            if (characteristic.uuid.toString().toLowerCase() ==
                CHARACTERISTIC_UUID.toLowerCase()) {
              targetCharacteristic = characteristic;
              print("✓ Found target characteristic: ${characteristic.uuid}");
              print("Characteristic properties:");
              print("  - Read: ${characteristic.properties.read}");
              print("  - Write: ${characteristic.properties.write}");
              print(
                  "  - WriteWithoutResponse: ${characteristic.properties.writeWithoutResponse}");
              print("  - Notify: ${characteristic.properties.notify}");

              // Update UI state
              setState(() {});

              // Navigate directly to controller selection screen
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ControllerSelectionScreen(
                      device: device,
                      characteristic: characteristic,
                    ),
                  ),
                );
              }

              // Enable notifications if supported
              if (characteristic.properties.notify) {
                await characteristic.setNotifyValue(true);
                print("✓ Notifications enabled");
              }
              break; // Found our characteristic, stop looking
            }
          }
          break; // Found our service, stop looking
        }
      }

      if (targetCharacteristic == null) {
        print("✗ Warning: Target characteristic not found!");
        print("Please check that the ESP32 firmware has the correct UUIDs:");
        print("  Service: $SERVICE_UUID");
        print("  Characteristic: $CHARACTERISTIC_UUID");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Error: Service/Characteristic not found!\nCheck ESP32 UUIDs in firmware."),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'View Logs',
                textColor: Colors.white,
                onPressed: () {
                  // Logs are already printed to console
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print("✗ Error discovering services: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Connection Error: $e"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("ESP32 BLE Connect"), backgroundColor: Colors.blue),
      body: connectedDevice == null ? _buildScanUI() : _buildLoadingUI(),
    );
  }

  /// Loading UI while discovering services
  Widget _buildLoadingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            "Connecting to ${connectedDevice!.platformName}...",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          const Text(
            "Discovering services...",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// UI for scanning devices
  Widget _buildScanUI() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Image.asset(
          'assets/lionbit_car.png',
          width: 160,
          height: 160,
        ),
        const SizedBox(height: 10),
        const Text(
          "LionBit BLE Communicator",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: startScan,
          child: const Text("Scan for Devices"),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: scannedDevices.length,
            itemBuilder: (context, index) {
              BluetoothDevice device = scannedDevices[index];
              String deviceName = device.platformName.isNotEmpty
                  ? device.platformName
                  : "Unknown Device";
              bool isLionBit = deviceName == "LionBit_BLE";

              return ListTile(
                leading: isLionBit
                    ? Image.asset(
                        'assets/lionbit_car.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      )
                    : const Icon(Icons.bluetooth, color: Colors.blue),
                title: Text(deviceName),
                subtitle: Text(device.remoteId.toString()),
                onTap: () => connectToDevice(device),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Controller Selection Screen
class ControllerSelectionScreen extends StatelessWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  const ControllerSelectionScreen({
    super.key,
    required this.device,
    required this.characteristic,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Controller Type"),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/lionbit_car.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 20),
              Text(
                "Connected to: ${device.platformName}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              _buildControllerOption(
                context,
                icon: Icons.lightbulb,
                title: "LED Controller",
                subtitle: "RGB LEDs, Brightness, Colors",
                color: Colors.amber,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LEDControlScreen(
                        device: device,
                        characteristic: characteristic,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildControllerOption(
                context,
                icon: Icons.directions_car,
                title: "Vehicle Controller",
                subtitle: "2-Wheel, 4-Wheel, Advanced",
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VehicleControllerTypeScreen(
                        device: device,
                        characteristic: characteristic,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildControllerOption(
                context,
                icon: Icons.toggle_on,
                title: "Switches",
                subtitle: "Toggle outputs, relays, devices",
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SwitchesControlScreen(
                        device: device,
                        characteristic: characteristic,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildControllerOption(
                context,
                icon: Icons.sports_esports,
                title: "Gamepad",
                subtitle: "Virtual joystick & action buttons",
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GamepadControlScreen(
                        device: device,
                        characteristic: characteristic,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildControllerOption(
                context,
                icon: Icons.sensors,
                title: "Sensor Display",
                subtitle: "View digital & analog sensor readings",
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SensorDisplayScreen(
                        device: device,
                        characteristic: characteristic,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildControllerOption(
                context,
                icon: Icons.terminal,
                title: "Terminal",
                subtitle: "Send custom commands",
                color: Colors.black87,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TerminalControlScreen(
                        device: device,
                        characteristic: characteristic,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildControllerOption(
                context,
                icon: Icons.mic,
                title: "Voice Terminal",
                subtitle: "Voice-controlled commands",
                color: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VoiceTerminalScreen(
                        device: device,
                        characteristic: characteristic,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControllerOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// VEHICLE CONTROLLER TYPE SELECTION SCREEN
// ============================================
class VehicleControllerTypeScreen extends StatelessWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  const VehicleControllerTypeScreen({
    super.key,
    required this.device,
    required this.characteristic,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Vehicle Type"),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car, size: 100, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                "Connected to: ${device.platformName}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              _buildVehicleTypeOption(
                context,
                icon: Icons.two_wheeler,
                title: "2-Wheel Driver",
                subtitle: "Bike, Motorcycle, Segway",
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TwoWheelControlScreen(
                        device: device,
                        characteristic: characteristic,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildVehicleTypeOption(
                context,
                icon: Icons.directions_car,
                title: "4-Wheel Driver",
                subtitle: "Car, RC Car, Rover",
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FourWheelControlScreen(
                        device: device,
                        characteristic: characteristic,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _buildVehicleTypeOption(
                context,
                icon: Icons.settings_input_component,
                title: "Advanced Control",
                subtitle: "Armed Devices, Multi-Wheelers, Custom",
                color: Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdvancedControlScreen(
                        device: device,
                        characteristic: characteristic,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleTypeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================
// LED CONTROLLER SCREEN
// ============================================
class LEDControlScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  const LEDControlScreen({
    super.key,
    required this.device,
    required this.characteristic,
  });

  @override
  State<LEDControlScreen> createState() => _LEDControlScreenState();
}

class _LEDControlScreenState extends State<LEDControlScreen> {
  Color currentColor = Colors.red;
  double brightness = 255;
  bool isOn = true;

  void sendLEDCommand(String command) async {
    try {
      await widget.characteristic.write(
        utf8.encode(command),
        withoutResponse: widget.characteristic.properties.writeWithoutResponse,
      );
      print("LED Command sent: $command");
    } catch (e) {
      print("Error sending LED command: $e");
    }
  }

  void updateLED() {
    int r = currentColor.red;
    int g = currentColor.green;
    int b = currentColor.blue;
    int bright = brightness.toInt();

    if (!isOn) {
      sendLEDCommand("LED:OFF");
    } else {
      sendLEDCommand("LED:$r,$g,$b,$bright");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LED Controller"),
        backgroundColor: Colors.amber,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.amber.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.lightbulb, size: 100, color: Colors.amber),
                const SizedBox(height: 10),
                Text(
                  "Connected to: ${widget.device.platformName}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // LED Status
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isOn ? currentColor : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isOn
                            ? currentColor.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    isOn ? "LED ON" : "LED OFF",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // On/Off Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("OFF",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Switch(
                      value: isOn,
                      onChanged: (value) {
                        setState(() {
                          isOn = value;
                        });
                        updateLED();
                      },
                      activeColor: Colors.amber,
                    ),
                    const SizedBox(width: 10),
                    const Text("ON",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),

                const SizedBox(height: 30),

                // Color Picker
                const Text(
                  "Select Color",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                BlockPicker(
                  pickerColor: currentColor,
                  onColorChanged: (color) {
                    setState(() {
                      currentColor = color;
                    });
                    updateLED();
                  },
                ),

                const SizedBox(height: 30),

                // Brightness Slider
                const Text(
                  "Brightness",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.brightness_low),
                    Expanded(
                      child: Slider(
                        value: brightness,
                        min: 0,
                        max: 255,
                        divisions: 255,
                        label: brightness.toInt().toString(),
                        onChanged: (value) {
                          setState(() {
                            brightness = value;
                          });
                        },
                        onChangeEnd: (value) {
                          updateLED();
                        },
                      ),
                    ),
                    const Icon(Icons.brightness_high),
                  ],
                ),

                const SizedBox(height: 30),

                // Quick Color Buttons
                const Text(
                  "Quick Colors",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildQuickColorButton(Colors.red, "Red"),
                    _buildQuickColorButton(Colors.green, "Green"),
                    _buildQuickColorButton(Colors.blue, "Blue"),
                    _buildQuickColorButton(Colors.yellow, "Yellow"),
                    _buildQuickColorButton(Colors.purple, "Purple"),
                    _buildQuickColorButton(Colors.orange, "Orange"),
                    _buildQuickColorButton(Colors.cyan, "Cyan"),
                    _buildQuickColorButton(Colors.white, "White"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickColorButton(Color color, String label) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          currentColor = color;
          isOn = true;
        });
        updateLED();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================
// SWITCHES CONTROLLER SCREEN
// ============================================
class SwitchesControlScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  const SwitchesControlScreen({
    super.key,
    required this.device,
    required this.characteristic,
  });

  @override
  State<SwitchesControlScreen> createState() => _SwitchesControlScreenState();
}

class _SwitchesControlScreenState extends State<SwitchesControlScreen> {
  List<bool> switchStates = List.generate(11, (index) => false);

  void sendSwitchCommand(int pinNumber, bool state) async {
    try {
      String command = "D$pinNumber:${state ? 'ON' : 'OFF'}";
      await widget.characteristic.write(
        utf8.encode(command),
        withoutResponse: widget.characteristic.properties.writeWithoutResponse,
      );
      print("Switch command sent: $command");
    } catch (e) {
      print("Error sending switch command: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Switches Controller"),
        backgroundColor: Colors.green,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.toggle_on, size: 100, color: Colors.green),
            const SizedBox(height: 10),
            Text(
              "Connected to: ${widget.device.platformName}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: 11,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemBuilder: (context, index) {
                  int pinNumber = index + 2; // D2 to D12
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: Icon(
                        switchStates[index] ? Icons.power : Icons.power_off,
                        color: switchStates[index] ? Colors.green : Colors.grey,
                        size: 35,
                      ),
                      title: Text(
                        "D$pinNumber",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        switchStates[index] ? "ON" : "OFF",
                        style: TextStyle(
                          color:
                              switchStates[index] ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Switch(
                        value: switchStates[index],
                        onChanged: (value) {
                          setState(() {
                            switchStates[index] = value;
                          });
                          sendSwitchCommand(pinNumber, value);
                        },
                        activeColor: Colors.green,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          for (int i = 0; i < switchStates.length; i++) {
                            switchStates[i] = true;
                            sendSwitchCommand(i + 2, true); // D2 to D12
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        "ALL ON",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          for (int i = 0; i < switchStates.length; i++) {
                            switchStates[i] = false;
                            sendSwitchCommand(i + 2, false); // D2 to D12
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        "ALL OFF",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// GAMEPAD CONTROLLER SCREEN
// ============================================
class GamepadControlScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  const GamepadControlScreen({
    super.key,
    required this.device,
    required this.characteristic,
  });

  @override
  State<GamepadControlScreen> createState() => _GamepadControlScreenState();
}

class _GamepadControlScreenState extends State<GamepadControlScreen> {
  String currentCommand = "IDLE";
  String pressedButton = "";

  void sendCommand(String command) async {
    try {
      await widget.characteristic.write(
        utf8.encode(command),
        withoutResponse: widget.characteristic.properties.writeWithoutResponse,
      );
      setState(() {
        currentCommand = command;
      });
      print("Gamepad command sent: $command");
    } catch (e) {
      print("Error sending gamepad command: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gamepad Controller"),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.sports_esports, size: 100, color: Colors.purple),
            const SizedBox(height: 10),
            Text(
              "Connected to: ${widget.device.platformName}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Command: $currentCommand",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Left D-Pad
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "D-PAD",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              _buildDPad(),
                            ],
                          ),

                          // Right Action Buttons
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "ACTIONS",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              _buildActionButtons(),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Bottom Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBottomButton("L1", Colors.grey),
                          const SizedBox(width: 20),
                          _buildBottomButton("START", Colors.orange),
                          const SizedBox(width: 20),
                          _buildBottomButton("R1", Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDPad() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGameButton(Icons.arrow_upward, "UP"),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGameButton(Icons.arrow_back, "LEFT"),
            const SizedBox(width: 10),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            _buildGameButton(Icons.arrow_forward, "RIGHT"),
          ],
        ),
        const SizedBox(height: 10),
        _buildGameButton(Icons.arrow_downward, "DOWN"),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton("Y", Colors.yellow),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton("X", Colors.blue),
            const SizedBox(width: 10),
            Container(
              width: 50,
              height: 50,
            ),
            const SizedBox(width: 10),
            _buildActionButton("B", Colors.red),
          ],
        ),
        const SizedBox(height: 10),
        _buildActionButton("A", Colors.green),
      ],
    );
  }

  Widget _buildGameButton(IconData icon, String command) {
    bool isPressed = pressedButton == command;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => pressedButton = command);
        sendCommand(command);
      },
      onTapUp: (_) {
        setState(() => pressedButton = "");
        sendCommand("STOP");
      },
      onTapCancel: () {
        setState(() => pressedButton = "");
        sendCommand("STOP");
      },
      child: AnimatedScale(
        scale: isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.purple,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: isPressed ? 2 : 5,
                offset: Offset(0, isPressed ? 1 : 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color) {
    bool isPressed = pressedButton == label;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => pressedButton = label);
        sendCommand(label);
      },
      onTapUp: (_) {
        setState(() => pressedButton = "");
        sendCommand("STOP");
      },
      onTapCancel: () {
        setState(() => pressedButton = "");
        sendCommand("STOP");
      },
      child: AnimatedScale(
        scale: isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: isPressed ? 2 : 5,
                offset: Offset(0, isPressed ? 1 : 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(String label, Color color) {
    bool isPressed = pressedButton == label;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => pressedButton = label);
        sendCommand(label);
      },
      onTapUp: (_) {
        setState(() => pressedButton = "");
      },
      onTapCancel: () {
        setState(() => pressedButton = "");
      },
      child: AnimatedScale(
        scale: isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: isPressed ? 2 : 5,
                offset: Offset(0, isPressed ? 1 : 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// TERMINAL CONTROLLER SCREEN
// ============================================
class TerminalControlScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  const TerminalControlScreen({
    super.key,
    required this.device,
    required this.characteristic,
  });

  @override
  State<TerminalControlScreen> createState() => _TerminalControlScreenState();
}

class _TerminalControlScreenState extends State<TerminalControlScreen> {
  List<Map<String, dynamic>> terminalMessages = [];
  TextEditingController commandController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen for incoming data
    widget.characteristic.lastValueStream.listen((value) {
      if (value.isNotEmpty) {
        String message = utf8.decode(value);
        setState(() {
          terminalMessages.insert(0, {
            "text": message,
            "isSent": false,
          });
        });
      }
    });
  }

  void sendCommand() async {
    if (commandController.text.isEmpty) return;

    String command = commandController.text.trim();
    try {
      await widget.characteristic.write(
        utf8.encode(command),
        withoutResponse: widget.characteristic.properties.writeWithoutResponse,
      );

      setState(() {
        terminalMessages.insert(0, {
          "text": "> $command",
          "isSent": true,
        });
      });

      commandController.clear();
    } catch (e) {
      print("Error sending command: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terminal Controller",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(221, 0, 0, 0),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              setState(() {
                terminalMessages.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey[900],
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Connected to: ${widget.device.platformName}",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(10),
              child: ListView.builder(
                reverse: true,
                itemCount: terminalMessages.length,
                itemBuilder: (context, index) {
                  bool isSent = terminalMessages[index]["isSent"];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      terminalMessages[index]["text"],
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Courier',
                        color: isSent
                            ? Colors.lightGreenAccent
                            : Colors.lightBlueAccent,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(top: BorderSide(color: Colors.grey[700]!)),
            ),
            child: Row(
              children: [
                const Text(
                  ">",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: commandController,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Enter command...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => sendCommand(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: sendCommand,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// VOICE TERMINAL SCREEN
// ============================================
class VoiceTerminalScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  const VoiceTerminalScreen({
    super.key,
    required this.device,
    required this.characteristic,
  });

  @override
  State<VoiceTerminalScreen> createState() => _VoiceTerminalScreenState();
}

class _VoiceTerminalScreenState extends State<VoiceTerminalScreen> {
  List<Map<String, dynamic>> terminalMessages = [];
  bool isListening = false;
  String recognizedText = "";
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();

    // Listen for incoming data
    widget.characteristic.lastValueStream.listen((value) {
      if (value.isNotEmpty) {
        String message = utf8.decode(value);
        setState(() {
          terminalMessages.insert(0, {
            "text": message,
            "isSent": false,
          });
        });
      }
    });
  }

  void _initSpeech() async {
    // Request microphone permission
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Microphone permission is required for voice commands"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onError: (error) {
        print('Speech recognition error: $error');
        if (mounted) {
          setState(() {
            isListening = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Speech error: ${error.errorMsg}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() {
              isListening = false;
            });
          }
        }
      },
    );

    if (!_speechAvailable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Speech recognition not available on this device"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void sendVoiceCommand(String command) async {
    if (command.isEmpty) return;

    try {
      await widget.characteristic.write(
        utf8.encode(command),
        withoutResponse: widget.characteristic.properties.writeWithoutResponse,
      );

      setState(() {
        terminalMessages.insert(0, {
          "text": "🎤 $command",
          "isSent": true,
        });
      });
    } catch (e) {
      print("Error sending voice command: $e");
    }
  }

  void toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Speech recognition not available"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isListening) {
      // Stop listening
      await _speech.stop();
      setState(() {
        isListening = false;
      });
    } else {
      // Start listening
      setState(() {
        isListening = true;
        recognizedText = "";
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            recognizedText = result.recognizedWords;
          });

          // If speech is finalized, send the command
          if (result.finalResult) {
            if (recognizedText.isNotEmpty) {
              sendVoiceCommand(recognizedText);
            }
            setState(() {
              isListening = false;
              recognizedText = "";
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Voice Terminal"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() {
                terminalMessages.clear();
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              color: Colors.red[100],
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Connected to: ${widget.device.platformName}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Microphone Button
            GestureDetector(
              onTapDown: (_) => toggleListening(),
              onTapUp: (_) => toggleListening(),
              onTapCancel: () {
                if (isListening) toggleListening();
              },
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: isListening ? Colors.red : Colors.grey[300],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isListening
                          ? Colors.red.withOpacity(0.5)
                          : Colors.grey.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isListening ? "Listening..." : "Tap to speak",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isListening ? Colors.red : Colors.grey,
              ),
            ),

            // Display recognized text while listening
            if (recognizedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Text(
                    recognizedText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // Quick Voice Commands
            const Text(
              "Quick Commands",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildQuickCommand("Forward"),
                _buildQuickCommand("Backward"),
                _buildQuickCommand("Left"),
                _buildQuickCommand("Right"),
                _buildQuickCommand("Stop"),
                _buildQuickCommand("LED On"),
                _buildQuickCommand("LED Off"),
                _buildQuickCommand("Clear"),
              ],
            ),

            const SizedBox(height: 20),

            // Terminal Messages
            const Text(
              "Message Log",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: ListView.builder(
                  reverse: true,
                  itemCount: terminalMessages.length,
                  itemBuilder: (context, index) {
                    bool isSent = terminalMessages[index]["isSent"];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        terminalMessages[index]["text"],
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Courier',
                          color: isSent
                              ? Colors.lightGreenAccent
                              : Colors.lightBlueAccent,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCommand(String command) {
    return ElevatedButton(
      onPressed: () => sendVoiceCommand(command),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(
        command,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}

// ============================================
// CAR CONTROLLER (4-WHEEL) - Keep existing
// ============================================
class TwoWheelControlScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  const TwoWheelControlScreen({
    super.key,
    required this.device,
    required this.characteristic,
  });

  @override
  State<TwoWheelControlScreen> createState() => _TwoWheelControlScreenState();
}

class _TwoWheelControlScreenState extends State<TwoWheelControlScreen> {
  String currentDirection = "STOP";
  String pressedButton = "";
  bool isHornActive = false;
  bool isLightActive = false;

  void sendCommand(String command) async {
    try {
      await widget.characteristic.write(
        utf8.encode(command),
        withoutResponse: widget.characteristic.properties.writeWithoutResponse,
      );
      setState(() {
        currentDirection = command;
      });
      print("Command sent: $command");
    } catch (e) {
      print("Error sending command: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("2-Wheel Control"),
        backgroundColor: Colors.orange,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.two_wheeler, size: 100, color: Colors.orange),
            const SizedBox(height: 10),
            Text(
              "Connected to: ${widget.device.platformName}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Status: $currentDirection",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Forward button with Horn and Light on sides
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          icon: Icons.music_note,
                          label: isHornActive ? "HORN ON" : "HORN OFF",
                          onTap: () {
                            setState(() {
                              isHornActive = !isHornActive;
                            });
                            sendCommand(isHornActive ? "HORN:ON" : "HORN:OFF");
                          },
                          color: isHornActive ? Colors.amber : Colors.grey,
                          isActive: isHornActive,
                        ),
                        const SizedBox(width: 20),
                        _buildControlButton(
                          icon: Icons.arrow_upward,
                          label: "FORWARD",
                          onTapDown: () => sendCommand("F"),
                          onTapUp: () => sendCommand("S"),
                        ),
                        const SizedBox(width: 20),
                        _buildActionButton(
                          icon: Icons.lightbulb,
                          label: isLightActive ? "LIGHT ON" : "LIGHT OFF",
                          onTap: () {
                            setState(() {
                              isLightActive = !isLightActive;
                            });
                            sendCommand(
                                isLightActive ? "LIGHT:ON" : "LIGHT:OFF");
                          },
                          color: isLightActive ? Colors.yellow : Colors.grey,
                          isActive: isLightActive,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Left Lean and Right Lean
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildControlButton(
                          icon: Icons.rotate_left,
                          label: "LEAN LEFT",
                          onTapDown: () => sendCommand("L"),
                          onTapUp: () => sendCommand("S"),
                        ),
                        const SizedBox(width: 40),
                        _buildControlButton(
                          icon: Icons.stop,
                          label: "STOP",
                          onTapDown: () => sendCommand("S"),
                          onTapUp: () => sendCommand("S"),
                          color: Colors.red,
                        ),
                        const SizedBox(width: 40),
                        _buildControlButton(
                          icon: Icons.rotate_right,
                          label: "LEAN RIGHT",
                          onTapDown: () => sendCommand("R"),
                          onTapUp: () => sendCommand("S"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // Backward/Brake button
                    _buildControlButton(
                      icon: Icons.arrow_downward,
                      label: "BACKWARD",
                      onTapDown: () => sendCommand("B"),
                      onTapUp: () => sendCommand("S"),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    Color? color,
  }) {
    bool isPressed = pressedButton == label;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => pressedButton = label);
        onTapDown();
      },
      onTapUp: (_) {
        setState(() => pressedButton = "");
        onTapUp();
      },
      onTapCancel: () {
        setState(() => pressedButton = "");
        onTapUp();
      },
      child: AnimatedScale(
        scale: isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: color ?? Colors.orange,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isActive = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            scale: isActive ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: isActive ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// 4-Wheel Control Screen (renamed from CarControlScreen)
class FourWheelControlScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  const FourWheelControlScreen({
    super.key,
    required this.device,
    required this.characteristic,
  });

  @override
  State<FourWheelControlScreen> createState() => _FourWheelControlScreenState();
}

class _FourWheelControlScreenState extends State<FourWheelControlScreen> {
  String currentDirection = "STOP";
  String pressedButton = "";
  bool isHornActive = false;
  bool isLightActive = false;

  void sendCommand(String command) async {
    try {
      await widget.characteristic.write(
        utf8.encode(command),
        withoutResponse: widget.characteristic.properties.writeWithoutResponse,
      );
      setState(() {
        currentDirection = command;
      });
      print("Command sent: $command");
    } catch (e) {
      print("Error sending command: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("4-Wheel Control"),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Image.asset(
              'assets/lionbit_car.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 10),
            Text(
              "Connected to: ${widget.device.platformName}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Direction: $currentDirection",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Joystick Controls
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Forward button with Horn and Light on sides
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          icon: Icons.music_note,
                          label: isHornActive ? "HORN ON" : "HORN OFF",
                          onTap: () {
                            setState(() {
                              isHornActive = !isHornActive;
                            });
                            sendCommand(isHornActive ? "HORN:ON" : "HORN:OFF");
                          },
                          color: isHornActive ? Colors.amber : Colors.grey,
                          isActive: isHornActive,
                        ),
                        const SizedBox(width: 20),
                        _buildControlButton(
                          icon: Icons.arrow_upward,
                          label: "FORWARD",
                          onTapDown: () => sendCommand("F"),
                          onTapUp: () => sendCommand("S"),
                        ),
                        const SizedBox(width: 20),
                        _buildActionButton(
                          icon: Icons.lightbulb,
                          label: isLightActive ? "LIGHT ON" : "LIGHT OFF",
                          onTap: () {
                            setState(() {
                              isLightActive = !isLightActive;
                            });
                            sendCommand(
                                isLightActive ? "LIGHT:ON" : "LIGHT:OFF");
                          },
                          color: isLightActive ? Colors.yellow : Colors.grey,
                          isActive: isLightActive,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Left, Stop, Right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildControlButton(
                          icon: Icons.arrow_back,
                          label: "LEFT",
                          onTapDown: () => sendCommand("L"),
                          onTapUp: () => sendCommand("S"),
                        ),
                        const SizedBox(width: 20),
                        _buildControlButton(
                          icon: Icons.stop,
                          label: "STOP",
                          onTapDown: () => sendCommand("S"),
                          onTapUp: () => sendCommand("S"),
                          color: Colors.red,
                        ),
                        const SizedBox(width: 20),
                        _buildControlButton(
                          icon: Icons.arrow_forward,
                          label: "RIGHT",
                          onTapDown: () => sendCommand("R"),
                          onTapUp: () => sendCommand("S"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Backward button
                    _buildControlButton(
                      icon: Icons.arrow_downward,
                      label: "BACKWARD",
                      onTapDown: () => sendCommand("B"),
                      onTapUp: () => sendCommand("S"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    Color? color,
  }) {
    bool isPressed = pressedButton == label;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => pressedButton = label);
        onTapDown();
      },
      onTapUp: (_) {
        setState(() => pressedButton = "");
        onTapUp();
      },
      onTapCancel: () {
        setState(() => pressedButton = "");
        onTapUp();
      },
      child: AnimatedScale(
        scale: isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: color ?? Colors.blue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool isActive = false,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedScale(
            scale: isActive ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: isActive ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// Advanced Control Screen for armed devices and multi-wheelers
class AdvancedControlScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  const AdvancedControlScreen({
    super.key,
    required this.device,
    required this.characteristic,
  });

  @override
  State<AdvancedControlScreen> createState() => _AdvancedControlScreenState();
}

class _AdvancedControlScreenState extends State<AdvancedControlScreen> {
  String currentCommand = "IDLE";
  bool isArmed = false;
  String pressedButton = "";
  double speedSlider = 0.0;
  double steeringSlider = 0.0;

  void sendCommand(String command) async {
    try {
      await widget.characteristic.write(
        utf8.encode(command),
        withoutResponse: widget.characteristic.properties.writeWithoutResponse,
      );
      setState(() {
        currentCommand = command;
      });
      print("Command sent: $command");
    } catch (e) {
      print("Error sending command: $e");
    }
  }

  void toggleArm() {
    setState(() {
      isArmed = !isArmed;
      sendCommand(isArmed ? "ARM" : "DISARM");
    });
  }

  void sendSliderCommand() {
    if (isArmed) {
      int speed = speedSlider.toInt();
      int steering = steeringSlider.toInt();
      sendCommand("SLIDER:$speed,$steering");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Advanced Control"),
        backgroundColor: Colors.red,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.settings_input_component,
                  size: 100, color: Colors.red),
              const SizedBox(height: 10),
              Text(
                "Connected to: ${widget.device.platformName}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isArmed ? Colors.red.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isArmed ? "ARMED - $currentCommand" : "DISARMED - Safe Mode",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isArmed ? Colors.red : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Arm/Disarm Toggle
              ElevatedButton.icon(
                onPressed: toggleArm,
                icon: Icon(isArmed ? Icons.shield : Icons.shield_outlined),
                label: Text(isArmed ? "DISARM SYSTEM" : "ARM SYSTEM"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isArmed ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
              const SizedBox(height: 20),
              // Primary Movement Controls
              Column(
                children: [
                  // Primary Movement Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon: Icons.north_west,
                        label: "FL",
                        command: "FL",
                        enabled: isArmed,
                      ),
                      const SizedBox(width: 10),
                      _buildControlButton(
                        icon: Icons.arrow_upward,
                        label: "FWD",
                        command: "F",
                        enabled: isArmed,
                      ),
                      const SizedBox(width: 10),
                      _buildControlButton(
                        icon: Icons.north_east,
                        label: "FR",
                        command: "FR",
                        enabled: isArmed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon: Icons.arrow_back,
                        label: "LEFT",
                        command: "L",
                        enabled: isArmed,
                      ),
                      const SizedBox(width: 10),
                      _buildControlButton(
                        icon: Icons.stop,
                        label: "STOP",
                        command: "S",
                        enabled: true,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      _buildControlButton(
                        icon: Icons.arrow_forward,
                        label: "RIGHT",
                        command: "R",
                        enabled: isArmed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon: Icons.south_west,
                        label: "BL",
                        command: "BL",
                        enabled: isArmed,
                      ),
                      const SizedBox(width: 10),
                      _buildControlButton(
                        icon: Icons.arrow_downward,
                        label: "BACK",
                        command: "B",
                        enabled: isArmed,
                      ),
                      const SizedBox(width: 10),
                      _buildControlButton(
                        icon: Icons.south_east,
                        label: "BR",
                        command: "BR",
                        enabled: isArmed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Additional Advanced Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        icon: Icons.rotate_left,
                        label: "ROTATE L",
                        command: "RL",
                        enabled: isArmed,
                      ),
                      const SizedBox(width: 20),
                      _buildActionButton(
                        icon: Icons.rotate_right,
                        label: "ROTATE R",
                        command: "RR",
                        enabled: isArmed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        icon: Icons.flash_on,
                        label: "BOOST",
                        command: "BOOST",
                        enabled: isArmed,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 20),
                      _buildActionButton(
                        icon: Icons.light_mode,
                        label: "LIGHTS",
                        command: "LIGHT",
                        enabled: isArmed,
                        color: Colors.yellow,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Slider Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        const Text(
                          "Analog Controls",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Speed Slider
                        Row(
                          children: [
                            const Icon(Icons.speed, color: Colors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Speed: ${speedSlider.toInt()}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: Colors.red,
                                      inactiveTrackColor:
                                          Colors.red.withOpacity(0.3),
                                      thumbColor: Colors.red,
                                      overlayColor: Colors.red.withOpacity(0.2),
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 12),
                                    ),
                                    child: Slider(
                                      value: speedSlider,
                                      min: -100,
                                      max: 100,
                                      divisions: 200,
                                      onChanged: isArmed
                                          ? (value) {
                                              setState(() {
                                                speedSlider = value;
                                              });
                                            }
                                          : null,
                                      onChangeEnd: (value) {
                                        sendSliderCommand();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Steering Slider
                        Row(
                          children: [
                            const Icon(Icons.settings_ethernet,
                                color: Colors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Steering: ${steeringSlider.toInt()}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SliderTheme(
                                    data: SliderThemeData(
                                      activeTrackColor: Colors.red,
                                      inactiveTrackColor:
                                          Colors.red.withOpacity(0.3),
                                      thumbColor: Colors.red,
                                      overlayColor: Colors.red.withOpacity(0.2),
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 12),
                                    ),
                                    child: Slider(
                                      value: steeringSlider,
                                      min: -100,
                                      max: 100,
                                      divisions: 200,
                                      onChanged: isArmed
                                          ? (value) {
                                              setState(() {
                                                steeringSlider = value;
                                              });
                                            }
                                          : null,
                                      onChangeEnd: (value) {
                                        sendSliderCommand();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Reset Button
                        ElevatedButton.icon(
                          onPressed: isArmed
                              ? () {
                                  setState(() {
                                    speedSlider = 0.0;
                                    steeringSlider = 0.0;
                                  });
                                  sendSliderCommand();
                                }
                              : null,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Reset Sliders"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required String command,
    required bool enabled,
    Color? color,
  }) {
    bool isPressed = pressedButton == label;
    return GestureDetector(
      onTapDown: enabled
          ? (_) {
              setState(() => pressedButton = label);
              sendCommand(command);
            }
          : null,
      onTapUp: enabled
          ? (_) {
              setState(() => pressedButton = "");
              sendCommand("S");
            }
          : null,
      onTapCancel: enabled
          ? () {
              setState(() => pressedButton = "");
              sendCommand("S");
            }
          : null,
      child: AnimatedScale(
        scale: isPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.3,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color ?? Colors.red,
              shape: BoxShape.circle,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: Colors.white),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String command,
    required bool enabled,
    Color? color,
  }) {
    bool isPressed = pressedButton == label;
    return GestureDetector(
      onTap: enabled
          ? () {
              setState(() => pressedButton = label);
              sendCommand(command);
              Future.delayed(const Duration(milliseconds: 150), () {
                if (mounted) setState(() => pressedButton = "");
              });
            }
          : null,
      child: AnimatedScale(
        scale: isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: color ?? Colors.red,
              borderRadius: BorderRadius.circular(15),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// SENSOR DISPLAY SCREEN
// ============================================
class SensorDisplayScreen extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothCharacteristic characteristic;

  const SensorDisplayScreen({
    super.key,
    required this.device,
    required this.characteristic,
  });

  @override
  State<SensorDisplayScreen> createState() => _SensorDisplayScreenState();
}

class _SensorDisplayScreenState extends State<SensorDisplayScreen> {
  // Digital pins configuration (6 dropdowns)
  List<String> digitalPins = [
    'D0',
    'D1',
    'D2',
    'D3',
    'D4',
    'D5',
    'D6',
    'D7',
    'D8',
    'D9',
    'D10',
    'D11',
    'D12',
    'D13',
    'D14',
    'D15',
    'D16',
    'D17',
    'D18'
  ];
  List<String?> selectedDigitalPins = [null, null, null, null, null, null];
  List<String> digitalOutputs = ['--', '--', '--', '--', '--', '--'];

  // Analog pins configuration (4 dropdowns)
  List<String> analogPins = [
    'A0',
    'A1',
    'A2',
    'A3',
    'A4',
    'A5',
    'A6',
    'A7',
    'A8'
  ];
  List<String?> selectedAnalogPins = [null, null, null, null];
  List<String> analogOutputs = ['--', '--', '--', '--'];

  bool isReading = false;

  @override
  void initState() {
    super.initState();
    _startReadingLoop();
  }

  void _startReadingLoop() {
    // Request sensor readings every 500ms
    Future.doWhile(() async {
      if (!mounted) return false;
      await _requestSensorReadings();
      await Future.delayed(const Duration(milliseconds: 500));
      return mounted;
    });
  }

  Future<void> _requestSensorReadings() async {
    if (!mounted || isReading) return;

    setState(() => isReading = true);

    try {
      // Request digital readings
      for (int i = 0; i < selectedDigitalPins.length; i++) {
        if (selectedDigitalPins[i] != null) {
          String command = "READ_DIGITAL:${selectedDigitalPins[i]}";
          await widget.characteristic.write(
            utf8.encode(command),
            withoutResponse:
                widget.characteristic.properties.writeWithoutResponse,
          );
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      // Request analog readings
      for (int i = 0; i < selectedAnalogPins.length; i++) {
        if (selectedAnalogPins[i] != null) {
          String command = "READ_ANALOG:${selectedAnalogPins[i]}";
          await widget.characteristic.write(
            utf8.encode(command),
            withoutResponse:
                widget.characteristic.properties.writeWithoutResponse,
          );
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } catch (e) {
      print("Error requesting sensor readings: $e");
    } finally {
      if (mounted) {
        setState(() => isReading = false);
      }
    }
  }

  void _setupCharacteristicListener() {
    widget.characteristic.lastValueStream.listen((value) {
      if (!mounted) return;

      String response = utf8.decode(value);
      _parseResponse(response);
    });
  }

  void _parseResponse(String response) {
    // Parse responses like "D5:HIGH" or "A2:512"
    if (response.contains(':')) {
      List<String> parts = response.split(':');
      String pin = parts[0];
      String value = parts[1];

      // Update digital outputs
      for (int i = 0; i < selectedDigitalPins.length; i++) {
        if (selectedDigitalPins[i] == pin) {
          if (mounted) {
            setState(() {
              digitalOutputs[i] = value;
            });
          }
          break;
        }
      }

      // Update analog outputs
      for (int i = 0; i < selectedAnalogPins.length; i++) {
        if (selectedAnalogPins[i] == pin) {
          if (mounted) {
            setState(() {
              analogOutputs[i] = value;
            });
          }
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sensor Display"),
        backgroundColor: Colors.orange,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.sensors, size: 80, color: Colors.orange),
              const SizedBox(height: 10),
              Text(
                "Connected to: ${widget.device.platformName}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // DIGITAL SECTION
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.developer_board,
                            color: Colors.blue.shade700),
                        const SizedBox(width: 10),
                        Text(
                          "Digital Pins (D0-D18)",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ...List.generate(6, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.blue.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    hint: Text("Select Pin ${index + 1}"),
                                    value: selectedDigitalPins[index],
                                    items: digitalPins.map((pin) {
                                      return DropdownMenuItem(
                                        value: pin,
                                        child: Text(pin),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedDigitalPins[index] = value;
                                        digitalOutputs[index] = '--';
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.blue.shade300),
                                ),
                                child: Text(
                                  digitalOutputs[index],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: digitalOutputs[index] == 'HIGH'
                                        ? Colors.green
                                        : digitalOutputs[index] == 'LOW'
                                            ? Colors.red
                                            : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ANALOG SECTION
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.green.shade700),
                        const SizedBox(width: 10),
                        Text(
                          "Analog Pins (A0-A8)",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ...List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.green.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    hint: Text("Select Pin ${index + 1}"),
                                    value: selectedAnalogPins[index],
                                    items: analogPins.map((pin) {
                                      return DropdownMenuItem(
                                        value: pin,
                                        child: Text(pin),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedAnalogPins[index] = value;
                                        analogOutputs[index] = '--';
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.green.shade300),
                                ),
                                child: Text(
                                  analogOutputs[index],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: analogOutputs[index] != '--'
                                        ? Colors.green.shade700
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Info text
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Select pins from dropdowns to monitor their values in real-time",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
