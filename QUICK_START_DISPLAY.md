# Quick Start Guide - Display Setup

## What's Changed?

Your ESP32 firmware now displays all mobile app actions on a built-in OLED display!

## Two Options Available:

### Option 1: WITH OLED Display (Recommended)

**File:** `esp32_sample_sketch.ino`

**What You Need:**

- 128x64 OLED Display (SSD1306, I2C)
- 4 wires to connect display

**Arduino Libraries Required:**

1. Adafruit GFX Library
2. Adafruit SSD1306

**Display Shows:**

- Connection status (CONNECTED/DISCONNECTED)
- Last 3 commands from mobile app
- Real-time updates for every action

**Example Display:**

```
BLE Commands:
-------------
D2:ON
LED:255,0,0,200
F
```

### Option 2: WITHOUT Display (Serial Monitor Only)

**File:** `esp32_sample_sketch_serial_monitor.ino`

**What You Need:**

- Nothing extra! Just your ESP32

**Shows in Serial Monitor:**

- Formatted command boxes
- Command history
- Detailed processing info

**Example Serial Output:**

```
╔════════════════════════════════════════╗
║  COMMAND RECEIVED: D2:ON               ║
╠════════════════════════════════════════╣
║  RECENT COMMANDS:                      ║
║  1. D2:ON                              ║
║  2. F                                  ║
║  3. LED:OFF                            ║
╚════════════════════════════════════════╝
  Processing:   → Digital Pin D2 set to ON
  → GPIO 2 = HIGH
----------------------------------------
```

## Commands That Will Be Displayed:

### Switch Controls

- `D2:ON` - Turn on pin D2
- `D2:OFF` - Turn off pin D2
- Works for D2 through D12

### LED Controls

- `LED:255,0,0,200` - Red LED at brightness 200
- `LED:OFF` - Turn off LED
- Color format: RED,GREEN,BLUE,BRIGHTNESS

### Movement Controls

- `F` - Forward
- `B` - Backward
- `L` - Left
- `R` - Right
- `S` or `STOP` - Stop

### Vehicle Features

- `HORN:ON` - Horn on
- `HORN:OFF` - Horn off
- `HEADLIGHT:ON` - Headlight on
- `HEADLIGHT:OFF` - Headlight off

### Colors (LED presets)

- `RED`, `BLUE`, `GREEN`, `YELLOW`, `PURPLE`, `CYAN`, `WHITE`, `PINK`, `ORANGE`

### Sensor Commands

- `GET_DATA` - Request sensor data

## How to Upload:

1. **Open Arduino IDE**
2. **Choose your version:**
   - With display: Open `esp32_sample_sketch.ino`
   - Without display: Open `esp32_sample_sketch_serial_monitor.ino`
3. **Install libraries** (if using display version):
   - Tools → Manage Libraries → Search "Adafruit GFX" → Install
   - Tools → Manage Libraries → Search "Adafruit SSD1306" → Install
4. **Connect your ESP32**
5. **Select board:** Tools → Board → ESP32 Arduino → ESP32S3 Dev Module
6. **Select port:** Tools → Port → (your COM port)
7. **Click Upload**

## Testing:

1. Upload firmware to ESP32
2. Open Serial Monitor (115200 baud) to see logs
3. Open mobile app and connect to ESP32
4. Try any control:
   - Switch on D2
   - Change LED color
   - Move vehicle
   - Turn on horn
5. Watch the display (or Serial Monitor) update in real-time!

## Display Wiring (For Option 1):

```
OLED Display    →    ESP32-S3
─────────────────────────────
VCC             →    3.3V
GND             →    GND
SDA             →    GPIO 21*
SCL             →    GPIO 22*
```

\*Check your ESP32-S3 board pinout - some use GPIO 8 (SDA) and GPIO 9 (SCL)

## Troubleshooting:

### No display showing?

- Check all wire connections
- Verify I2C address (default is 0x3C)
- Run I2C scanner to find display address
- Check Serial Monitor for "Display initialized" message

### Display shows gibberish?

- Reset ESP32
- Check I2C address in code
- Try different I2C pins

### Serial Monitor works but display doesn't?

- Display may not be initialized - firmware will still function
- Check wiring and power to display
- Verify libraries are installed

### Commands not showing?

- Check BLE connection status
- Verify mobile app is connected
- Check Serial Monitor for "Received: " messages

## Need Help?

See full documentation in `DISPLAY_SETUP.md` for:

- Detailed hardware setup
- Customization options
- Advanced troubleshooting
- Code explanations
