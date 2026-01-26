# Display Connection Diagrams

## OLED Display Connection

### Standard Connection (Most ESP32-S3 Boards)

```
     ┌─────────────────┐
     │   OLED Display  │
     │    128x64 I2C   │
     │   (SSD1306)     │
     └────────┬────────┘
              │
    ┌─────────┴─────────┐
    │ VCC  GND  SDA  SCL│
    │  │    │    │    │ │
    │  │    │    │    │ │
    └──┼────┼────┼────┼─┘
       │    │    │    │
       │    │    │    │
     ┌─┴────┴────┴────┴─┐
     │ 3.3V GND G21 G22 │
     │                  │
     │    ESP32-S3      │
     │                  │
     └──────────────────┘
```

### Alternative Connection (Some ESP32-S3 Boards)

```
     ┌─────────────────┐
     │   OLED Display  │
     │    128x64 I2C   │
     │   (SSD1306)     │
     └────────┬────────┘
              │
    ┌─────────┴─────────┐
    │ VCC  GND  SDA  SCL│
    │  │    │    │    │ │
    │  │    │    │    │ │
    └──┼────┼────┼────┼─┘
       │    │    │    │
       │    │    │    │
     ┌─┴────┴────┴────┴─┐
     │ 3.3V GND G8  G9  │
     │                  │
     │    ESP32-S3      │
     │                  │
     └──────────────────┘
```

## Pin Mapping Tables

### Connection Table 1 (GPIO 21/22)

| OLED Pin | Wire Color\* | ESP32-S3 Pin | Function  |
| -------- | ------------ | ------------ | --------- |
| VCC      | Red          | 3.3V         | Power +   |
| GND      | Black        | GND          | Ground    |
| SDA      | Blue         | GPIO 21      | I2C Data  |
| SCL      | Yellow       | GPIO 22      | I2C Clock |

\*Wire colors are suggestions only

### Connection Table 2 (GPIO 8/9)

| OLED Pin | Wire Color\* | ESP32-S3 Pin | Function  |
| -------- | ------------ | ------------ | --------- |
| VCC      | Red          | 3.3V         | Power +   |
| GND      | Black        | GND          | Ground    |
| SDA      | Blue         | GPIO 8       | I2C Data  |
| SCL      | Yellow       | GPIO 9       | I2C Clock |

\*Wire colors are suggestions only

## Mobile App → ESP32 → Display Flow

```
┌─────────────────┐
│   Mobile App    │
│  (Flutter BLE)  │
└────────┬────────┘
         │
         │ BLE Command
         │ (e.g., "D2:ON")
         ▼
┌─────────────────┐
│     ESP32-S3    │
│  BLE Receiver   │
│                 │
│  ┌───────────┐  │
│  │  Process  │  │
│  │  Command  │  │
│  └─────┬─────┘  │
│        │        │
│        ├────────┼─► Serial Monitor
│        │        │   (Debug output)
│        │        │
│        ├────────┼─► GPIO Control
│        │        │   (D2 = HIGH)
│        │        │
│        └────────┼─► Display Update
│                 │
└────────┬────────┘
         │
         │ I2C Signal
         ▼
┌─────────────────┐
│  OLED Display   │
│    128x64       │
│                 │
│ BLE Commands:   │
│ -------------   │
│ D2:ON          │
│                 │
└─────────────────┘
```

## Display Examples

### Example 1: Switch Control

```
┌────────────────────┐
│ BLE Commands:      │
│ -------------      │
│ D2:ON              │
│ D5:OFF             │
│ D7:ON              │
└────────────────────┘
```

### Example 2: LED Control

```
┌────────────────────┐
│ BLE Commands:      │
│ -------------      │
│ LED:255,0,0,200    │
│ LED:0,255,0,255    │
│ LED:OFF            │
└────────────────────┘
```

### Example 3: Vehicle Control

```
┌────────────────────┐
│ BLE Commands:      │
│ -------------      │
│ F                  │
│ HORN:ON            │
│ STOP               │
└────────────────────┘
```

### Example 4: Connection Status

```
┌────────────────────┐
│Status: CONNECTED   │
│ -------------      │
│ Ready to receive   │
│ commands...        │
└────────────────────┘
```

### Example 5: Disconnected

```
┌────────────────────┐
│Status:DISCONNECTED │
│ -------------      │
│ Waiting for        │
│ connection...      │
└────────────────────┘
```

## System Architecture

```
┌──────────────────────────────────────────────────────────┐
│                     COMPLETE SYSTEM                       │
└──────────────────────────────────────────────────────────┘

┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│             │   BLE   │              │   I2C   │             │
│  Flutter    │◄───────►│   ESP32-S3   │◄───────►│    OLED     │
│  Mobile App │         │   with BLE   │         │   Display   │
│             │         │              │         │  128x64 px  │
└─────────────┘         └───────┬──────┘         └─────────────┘
                                │
                                │ Controls
                                ▼
                        ┌───────────────┐
                        │  GPIO Pins    │
                        │  D2 - D12     │
                        │               │
                        │  ├─► LED      │
                        │  ├─► Motor    │
                        │  ├─► Relay    │
                        │  └─► Sensors  │
                        └───────────────┘
```

## Data Flow Example

```
User Action in App:
  "Toggle Switch D2 to ON"
         │
         ▼
Flutter sends BLE:
  "D2:ON"
         │
         ▼
ESP32 receives:
  String rxValue = "D2:ON"
         │
         ├─► Serial.println("Received: D2:ON")
         │
         ├─► updateDisplay("D2:ON")
         │     └─► OLED shows: "D2:ON"
         │
         └─► handleDigitalPinCommand("D2:ON")
               └─► pinMode(2, OUTPUT)
               └─► digitalWrite(2, HIGH)
                     └─► Physical pin D2 goes HIGH
```

## Breadboard Layout Example

```
                    ┌──────────────────────┐
                    │     OLED Display     │
                    │      128x64 I2C      │
                    └──┬────┬────┬────┬────┘
                       │    │    │    │
                      VCC  GND  SDA  SCL
                       │    │    │    │
    ┌──────────────────┴────┴────┴────┴──────────────────┐
    │                  Breadboard                         │
    │  ===============================================    │
    │  ───────────────────────────────────────────────    │
    │  │││││││││││││││││││││││││││││││││││││││││││││    │
    │  ───────────────────────────────────────────────    │
    │  ───────────────────────────────────────────────    │
    │  │││││││││││││││││││││││││││││││││││││││││││││    │
    │  ===============================================    │
    └──────────────────────────────────────────────────────┘
                       │    │    │    │
                      3.3V GND  G21  G22
                       │    │    │    │
                    ┌──┴────┴────┴────┴────┐
                    │      ESP32-S3        │
                    │                      │
                    │  USB ═══════════     │
                    └──────────────────────┘
```

## Testing Checklist

- [ ] Display powers on (backlight visible)
- [ ] Initial message shows on display
- [ ] ESP32 appears in mobile app scan
- [ ] Successfully connect to ESP32
- [ ] Display shows "CONNECTED" status
- [ ] Send command from app
- [ ] Command appears on display
- [ ] Command appears in Serial Monitor
- [ ] GPIO responds correctly (if connected)
- [ ] Multiple commands show in history
- [ ] Disconnect works properly
- [ ] Display shows "DISCONNECTED" status
- [ ] Can reconnect successfully

## Common Display Types

### 1. 4-Pin OLED (I2C) - Recommended

```
┌──────────────┐
│ VCC GND SCL  │
│              │  ← Most common
│              │
│  128 x 64    │
└──────────────┘
```

### 2. 7-Pin OLED (SPI) - Not Compatible

```
┌──────────────┐
│ GND VCC SCL  │
│ SDA RES DC   │  ← Requires different code
│ CS           │
│  128 x 64    │
└──────────────┘
```

Note: This code is for I2C displays only!

## Tips

✅ **DO:**

- Use I2C OLED displays (4-pin)
- Check your ESP32-S3 pinout diagram
- Test with I2C scanner if display doesn't work
- Keep wires short (<15cm recommended)
- Use quality jumper wires

❌ **DON'T:**

- Use SPI displays without modifying code
- Mix up VCC and GND (will damage display!)
- Use 5V on 3.3V displays
- Connect while powered on (power off first)
