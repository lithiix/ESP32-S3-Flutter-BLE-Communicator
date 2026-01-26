#include "lionbitsupport.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define SERVICE_UUID        "12345678-1234-1234-1234-1234567890ab"
#define CHARACTERISTIC_UUID "87654321-4321-4321-4321-ba0987654321"

/* ---------- ULTRASONIC ADDED ---------- */
#define TRIG_PIN D12   // D12
#define ECHO_PIN D15   // D15
unsigned long lastUltrasonicUpdate = 0;
/* ------------------------------------ */

BLECharacteristic *pCharacteristic;
bool deviceConnected = false;
String lastMessage = "";

// ---------- FUNCTION TO READ ULTRASONIC DISTANCE ----------
float getUltrasonicDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  
  if (duration > 0) {
    float distance = (duration * 0.034) / 2;
    if (distance > 0 && distance < 400) {
      return distance;
    }
  }
  return -1; // Return -1 for invalid reading
}

// ---------- BLE SERVER CALLBACK ----------
class MyServerCallbacks : public BLEServerCallbacks {

  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    TextDisplay("CONNECTED");
    Serial.println("BLE Connected");
  }

  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    TextDisplay("WAITING");
    Serial.println("BLE Disconnected");
    BLEDevice::startAdvertising();
  }
};

// ---------- RECEIVE DATA CALLBACK ----------
class MyCallbacks : public BLECharacteristicCallbacks {

  void onWrite(BLECharacteristic *pCharacteristic) {

    String receivedText = pCharacteristic->getValue();
    receivedText.trim();

    if (receivedText.length() == 0) return;

    Serial.print("Received: ");
    Serial.println(receivedText);

    // Handle sensor read requests (READ:S1, READ:S2, etc.)
    if (receivedText.startsWith("READ:")) {
      String sensor = receivedText.substring(5); // Extract sensor name (S1, S2, etc.)
      String response = "";
      
      if (sensor == "S1") {
        // Read ultrasonic sensor
        float distance = getUltrasonicDistance();
        
        if (distance > 0) {
          response = "S1:" + String(distance, 1); // Format: S1:25.3
        } else {
          response = "S1:0"; // No valid reading
        }
        
        Serial.print("Sending: ");
        Serial.println(response);
      }
      else if (sensor == "S2") {
        response = "S2:0"; // S2 not configured
      }
      else if (sensor == "S3") {
        response = "S3:0"; // S3 not configured
      }
      else if (sensor == "S4") {
        response = "S4:0"; // S4 not configured
      }
      else if (sensor == "S5") {
        response = "S5:0"; // S5 not configured
      }
      else if (sensor == "S6") {
        response = "S6:0"; // S6 not configured
      }
      else if (sensor == "S7") {
        response = "S7:0"; // S7 not configured
      }
      
      // Send response back to app
      if (response.length() > 0) {
        pCharacteristic->setValue(response.c_str());
        pCharacteristic->notify();
      }
      return; // Don't update lastMessage or display for READ commands
    }

    // For non-READ commands, update lastMessage and display
    if (receivedText == lastMessage) return;
    lastMessage = receivedText;

    if (receivedText.equalsIgnoreCase("clear")) {
      ClsDis();
      lastMessage = "";
    }
    else {
      TextDisplay(receivedText);
    }
  }
};

void setup() {

  Serial.begin(115200);
  lionStart();

  /* ---------- ULTRASONIC ADDED ---------- */
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  TextColor(ST7735_YELLOW);
  TextSize(2);
  /* ------------------------------------ */

  TextDisplay("STARTING");
  delay(1000);

  BLEDevice::init("LionBit_BLE");

  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_WRITE |
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->addDescriptor(new BLE2902());

  pService->start();
  BLEDevice::getAdvertising()->start();

  TextDisplay("WAITING");
  Serial.println("BLE Ready");
}

void loop() {

  /* ---------- ULTRASONIC ADDED ---------- */
  // Display ultrasonic readings continuously
  // Only skip if lastMessage is a display command (not a READ command)
  // This allows the display to keep working even when connected to BLE

  if (millis() - lastUltrasonicUpdate >= 1000) {
    lastUltrasonicUpdate = millis();

    float distance = getUltrasonicDistance();

    // Only update display if no specific display message is being shown
    // (lastMessage is empty or it was a READ command which doesn't affect display)
    if (lastMessage == "" || lastMessage == "CONNECTED") {
      ClsDis();
      TextDisplay("OBJECT ");
      TextDisplay("DISTENCE ");

      if (distance > 0) {
        TextDisplay(String(distance, 1) + " CM");
      } else {
        TextDisplay("NOT DETECTED");
      }
    }
  }
  /* ------------------------------------ */
}
