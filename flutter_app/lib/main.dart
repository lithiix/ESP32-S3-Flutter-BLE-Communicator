import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

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
  List<Map<String, dynamic>> chatMessages = [];
  TextEditingController messageController = TextEditingController();

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
              'Please grant all permissions in the app settings.'
            ),
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

              // Show success message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✓ Device ready! You can send messages now."),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }

              // Enable notifications if supported
              if (characteristic.properties.notify) {
                await characteristic.setNotifyValue(true);
                print("✓ Notifications enabled");

                // Listen for incoming data from ESP32
                characteristic.lastValueStream.listen((value) {
                  if (value.isNotEmpty) {
                    String message = utf8.decode(value);
                    print("Received from ESP32: $message");
                    if (mounted) {
                      setState(() {
                        chatMessages.insert(0, {
                          "text": message,
                          "isSent": false,
                        });
                      });
                    }
                  }
                });
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

  /// Send a message from the mobile app to the ESP32
  void sendMessage() async {
    print("Send button pressed");
    print("targetCharacteristic is null: ${targetCharacteristic == null}");
    print("connectedDevice is null: ${connectedDevice == null}");

    if (targetCharacteristic == null) {
      print("Error: targetCharacteristic is null");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Not connected to device characteristic. Try reconnecting."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (messageController.text.isEmpty) {
      print("Error: Message is empty");
      return;
    }

    try {
      String message = messageController.text.trim();
      print("Attempting to send: $message");

      // Check which write type is supported
      bool withoutResponse =
          targetCharacteristic!.properties.writeWithoutResponse;
      bool withResponse = targetCharacteristic!.properties.write;

      print(
          "Write supported: $withResponse, WriteWithoutResponse: $withoutResponse");

      if (!withResponse && !withoutResponse) {
        print("Error: Characteristic does not support write operations");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Device characteristic cannot receive messages"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Write to characteristic (prefer withoutResponse for better performance)
      await targetCharacteristic!.write(
        utf8.encode(message),
        withoutResponse: withoutResponse,
      );

      print("Message sent successfully");

      // Clear the input field immediately after sending
      messageController.clear();

      if (mounted) {
        setState(() {
          chatMessages.insert(0, {
            "text": message,
            "isSent": true, // True means sent from mobile to ESP32
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Message sent!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("Error sending message: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send: $e"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Disconnect BLE device
  void disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      setState(() {
        connectedDevice = null;
        targetCharacteristic = null;
        chatMessages.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("ESP32 BLE Connect"), backgroundColor: Colors.blue),
      body: connectedDevice == null ? _buildScanUI() : _buildChatUI(),
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

  /// UI for Chat Messages
  Widget _buildChatUI() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          "Connected to: ${connectedDevice!.platformName}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: disconnectDevice,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Disconnect",
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  chatMessages.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Chat cleared"),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text("Clear Chat",
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ControllerSelectionScreen(
                      device: connectedDevice!,
                      characteristic: targetCharacteristic!,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Controllers",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            reverse: true, // Newest message on top
            itemCount: chatMessages.length,
            itemBuilder: (context, index) {
              return _buildChatBubble(chatMessages[index]);
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  /// Chat bubble for displaying messages
  Widget _buildChatBubble(Map<String, dynamic> message) {
    bool isSent = message["isSent"];
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSent ? Colors.blue[300] : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message["text"],
          style: TextStyle(
              fontSize: 16, color: isSent ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  /// Message input field
  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: sendMessage,
          ),
        ],
      ),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/lionbit_car.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 20),
              Text(
                "Connected to: ${device.platformName}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              _buildControllerOption(
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
              const SizedBox(height: 20),
              _buildControllerOption(
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
              const SizedBox(height: 20),
              _buildControllerOption(
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
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
    );
  }
}

// 2-Wheel Control Screen
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Forward/Accelerate button
                    _buildControlButton(
                      icon: Icons.arrow_upward,
                      label: "FORWARD",
                      onTapDown: () => sendCommand("F"),
                      onTapUp: () => sendCommand("S"),
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
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
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
                    // Forward button
                    _buildControlButton(
                      icon: Icons.arrow_upward,
                      label: "FORWARD",
                      onTapDown: () => sendCommand("F"),
                      onTapUp: () => sendCommand("S"),
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
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapUp,
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
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.settings_input_component,
                size: 100, color: Colors.red),
            const SizedBox(height: 10),
            Text(
              "Connected to: ${widget.device.platformName}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
    required String command,
    required bool enabled,
    Color? color,
  }) {
    return GestureDetector(
      onTapDown: enabled ? (_) => sendCommand(command) : null,
      onTapUp: enabled ? (_) => sendCommand("S") : null,
      onTapCancel: enabled ? () => sendCommand("S") : null,
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String command,
    required bool enabled,
    Color? color,
  }) {
    return GestureDetector(
      onTap: enabled ? () => sendCommand(command) : null,
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
    );
  }
}
