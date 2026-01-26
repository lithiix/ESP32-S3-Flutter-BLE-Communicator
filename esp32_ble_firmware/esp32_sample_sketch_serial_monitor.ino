#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// You can define your own UUIDs.:
#define SERVICE_UUID        "12345678-1234-1234-1234-1234567890ab"
#define CHARACTERISTIC_UUID "abcd1234-0000-1000-8000-00805f9b34fb"

BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic = nullptr;

// Flags to keep track of device connection
bool deviceConnected = false;

// Store last 3 commands
String lastCommands[3] = {"", "", ""};
int commandIndex = 0;

// Create a callback class to handle server events
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("\n========================================");
      Serial.println("    BLE CLIENT CONNECTED!");
      Serial.println("========================================");
      Serial.println("Status: READY TO RECEIVE COMMANDS");
      Serial.println("========================================\n");
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("\n========================================");
      Serial.println("    BLE CLIENT DISCONNECTED!");
      Serial.println("========================================");
      Serial.println("Waiting for new connection...");
      Serial.println("========================================\n");
      
      // Clear command history
      for (int i = 0; i < 3; i++) {
        lastCommands[i] = "";
      }
      commandIndex = 0;
      
      // Restart advertising so other devices can connect again
      pServer->getAdvertising()->start();
    }
};

  // Create a callback class to handle characteristic read/write requests
  class MyCallbacks: public BLECharacteristicCallbacks {
      
      //Return data onwrite "GET_DATA"
      void onWrite(BLECharacteristic *pCharacteristic) {
      String rxValue = pCharacteristic->getValue();

      if (rxValue.length() > 0) {
        // Display command with formatting
        displayCommand(rxValue);
        
        // Process specific commands
        if (rxValue == "GET_DATA") {
            // Example: Send fake sensor data
            String message = "Temp: 27.3°C | Humidity: 45%";
            pCharacteristic->setValue(message.c_str());
            pCharacteristic->notify();
            Serial.println("  → Sent sensor data to app");
        }
        // Handle LED commands
        else if (rxValue.startsWith("LED:")) {
          Serial.println("  → LED command processed");
          // Parse and handle LED control
        }
        // Handle digital pin commands (D2:ON, D5:OFF, etc.)
        else if (rxValue.indexOf("D") == 0 && rxValue.indexOf(":") > 0) {
          handleDigitalPinCommand(rxValue);
        }
        // Handle movement commands (F, B, L, R, S, etc.)
        else if (rxValue == "F" || rxValue == "B" || rxValue == "L" || 
                 rxValue == "R" || rxValue == "S" || rxValue == "STOP") {
          String movementType;
          if (rxValue == "F") movementType = "FORWARD";
          else if (rxValue == "B") movementType = "BACKWARD";
          else if (rxValue == "L") movementType = "LEFT";
          else if (rxValue == "R") movementType = "RIGHT";
          else if (rxValue == "S" || rxValue == "STOP") movementType = "STOP";
          
          Serial.print("  → Vehicle movement: ");
          Serial.println(movementType);
        }
        // Handle horn
        else if (rxValue.startsWith("HORN:")) {
          Serial.print("  → ");
          Serial.println(rxValue);
        }
        // Handle headlight
        else if (rxValue.startsWith("HEADLIGHT:")) {
          Serial.print("  → ");
          Serial.println(rxValue);
        }
        
        Serial.println("----------------------------------------\n");
      }
  }

};

void setup() {
  Serial.begin(115200);
  Serial.println("\n========================================");
  Serial.println("   ESP32-S3 BLE CONTROLLER");
  Serial.println("========================================");
  Serial.println("Starting BLE service...");

  // 1. Initialize the BLE device
  BLEDevice::init("ESP32-S3-BLE-Example");  // This is the device name you'll see on your phone

  // 2. Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // 3. Create a BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // 4. Create a BLE Characteristic
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );

  pCharacteristic->setCallbacks(new MyCallbacks());

  // Add a 2902 descriptor if you want notify/indicate to work in many apps
  pCharacteristic->addDescriptor(new BLE2902());

  // 5. Start the Service
  pService->start();

  // 6. Start advertising
  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  // By default, the ESP32 will advertise using the device name set above
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);

  BLEDevice::startAdvertising();
  Serial.println("✓ BLE advertising started");
  Serial.println("Device Name: ESP32-S3-BLE-Example");
  Serial.println("Waiting for connection...");
  Serial.println("========================================\n");
}

void loop() {

  // If connected, we can send a periodic notification (optional example)
  if (deviceConnected) {
    // For demonstration, send a simple string (or sensor data)
    static unsigned long lastSend = 0;
    if (millis() - lastSend > 2000) { // send every 2 seconds
      lastSend = millis();

      // Example data
      String message = "Hello from ESP32-S3: ";
      message += String(millis()/1000);
      pCharacteristic->setValue(message.c_str());
      pCharacteristic->notify();  // push to the client if it's subscribed
    }
  }
  delay(10);
}

// Function to display received commands with nice formatting
void displayCommand(String command) {
  // Store command in history
  lastCommands[commandIndex] = command;
  commandIndex = (commandIndex + 1) % 3;
  
  // Display current command
  Serial.println("╔════════════════════════════════════════╗");
  Serial.print("║  COMMAND RECEIVED: ");
  Serial.print(command);
  // Add padding
  int padding = 19 - command.length();
  for (int i = 0; i < padding; i++) {
    Serial.print(" ");
  }
  Serial.println("║");
  Serial.println("╠════════════════════════════════════════╣");
  
  // Show command history
  Serial.println("║  RECENT COMMANDS:                      ║");
  for (int i = 0; i < 3; i++) {
    int idx = (commandIndex - 1 - i + 3) % 3;
    if (lastCommands[idx].length() > 0) {
      Serial.print("║  ");
      Serial.print(i + 1);
      Serial.print(". ");
      Serial.print(lastCommands[idx]);
      // Add padding
      int cmdPadding = 34 - lastCommands[idx].length();
      for (int j = 0; j < cmdPadding; j++) {
        Serial.print(" ");
      }
      Serial.println("║");
    }
  }
  Serial.println("╚════════════════════════════════════════╝");
  Serial.print("  Processing: ");
}

// Function to handle digital pin commands like "D2:ON", "D5:OFF"
void handleDigitalPinCommand(String command) {
  int colonPos = command.indexOf(':');
  if (colonPos > 0) {
    String pinStr = command.substring(1, colonPos); // Extract pin number
    String state = command.substring(colonPos + 1); // Extract ON/OFF
    
    int pinNumber = pinStr.toInt();
    
    Serial.print("  → Digital Pin D");
    Serial.print(pinNumber);
    Serial.print(" set to ");
    Serial.println(state);
    
    // Configure and set the pin
    pinMode(pinNumber, OUTPUT);
    if (state == "ON") {
      digitalWrite(pinNumber, HIGH);
      Serial.print("  → GPIO ");
      Serial.print(pinNumber);
      Serial.println(" = HIGH");
    } else if (state == "OFF") {
      digitalWrite(pinNumber, LOW);
      Serial.print("  → GPIO ");
      Serial.print(pinNumber);
      Serial.println(" = LOW");
    }
  }
}
