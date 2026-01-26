# ESP32 Display Setup Guide

## Overview

The ESP32 firmware has been updated to display all BLE commands on a built-in OLED display (128x64 pixels, SSD1306). Every action you perform on the mobile app will be shown on the ESP32's display in real-time.

## Hardware Requirements

### Required Components:

1. **ESP32-S3 Board**
2. **OLED Display (SSD1306)**
   - Size: 128x64 pixels
   - Interface: I2C
   - Address: 0x3C (default)

### Display Connections:

Connect the OLED display to your ESP32-S3 using I2C:

| OLED Pin | ESP32-S3 Pin | Description |
| -------- | ------------ | ----------- |
| VCC      | 3.3V         | Power       |
| GND      | GND          | Ground      |
| SDA      | GPIO 21\*    | I2C Data    |
| SCL      | GPIO 22\*    | I2C Clock   |

\*Note: For ESP32-S3, default I2C pins may vary. Check your board's pinout. Common alternatives are GPIO 8 (SDA) and GPIO 9 (SCL).

## Software Requirements

### Arduino Libraries to Install:

Install these libraries via Arduino Library Manager:

1. **Adafruit GFX Library** by Adafruit
   - Provides graphics primitives
   - `Tools > Manage Libraries > Search "Adafruit GFX"`

2. **Adafruit SSD1306** by Adafruit
   - Driver for SSD1306 OLED displays
   - `Tools > Manage Libraries > Search "Adafruit SSD1306"`

## Display Features

### What Gets Displayed:

#### 1. **Connection Status**

- Shows "CONNECTED" when mobile app connects
- Shows "DISCONNECTED" when mobile app disconnects
- Shows "Waiting for connection..." on startup

#### 2. **Command History**

The display shows the last 3 commands received from the mobile app:

- Most recent command at top
- Commands are automatically truncated if too long (16 characters max)

#### 3. **Command Examples Shown on Display:**

**Switch Controls:**

```
D2:ON
D5:OFF
D7:ON
```

**LED Controls:**

```
LED:255,0,0,200
LED:OFF
```

**Movement Controls:**

```
F (Forward)
B (Backward)
L (Left)
R (Right)
S (Stop)
STOP
```

**Vehicle Features:**

```
HORN:ON
HORN:OFF
HEADLIGHT:ON
HEADLIGHT:OFF
```

**Color Commands:**

```
RED
BLUE
GREEN
YELLOW
```

**Sensor Requests:**

```
GET_DATA
```

## Display Layout

```
┌────────────────────┐
│ BLE Commands:      │
│ -------------      │
│ D2:ON              │ ← Most recent
│ LED:255,0,0,200    │ ← Previous
│ F                  │ ← Oldest
└────────────────────┘
```

## Customization

### Change I2C Pins (if needed):

If your ESP32-S3 uses different I2C pins, add this before `Wire.begin()` in setup():

```cpp
Wire.begin(SDA_PIN, SCL_PIN);  // Example: Wire.begin(8, 9);
```

### Change Display Address:

If your display uses a different I2C address (check with I2C scanner):

```cpp
#define SCREEN_ADDRESS 0x3D  // Change from 0x3C to 0x3D
```

### Adjust Text Size:

In the `updateDisplay()` function, change:

```cpp
display.setTextSize(1);  // Values: 1, 2, 3, etc.
```

### Show More/Fewer Commands:

Change the command history size:

```cpp
String lastCommands[5] = {"", "", "", "", ""};  // Change from 3 to 5
```

And update the loop in `updateDisplay()` accordingly.

## Troubleshooting

### Display Not Working:

1. **Check wiring** - Verify all connections are secure
2. **Check I2C address** - Run an I2C scanner sketch to find your display's address
3. **Check I2C pins** - Different ESP32 boards may use different default pins
4. **Check power** - Ensure display gets adequate power (3.3V or 5V depending on model)

### Display Shows Garbage:

- Reset ESP32
- Check if correct I2C address is used
- Verify libraries are properly installed

### Commands Not Showing:

- Check Serial Monitor to confirm commands are being received
- Verify BLE connection is established
- Ensure `updateDisplay()` function is being called

### Display Freezes:

- May need to add delay after display updates
- Check if display buffer is being properly cleared

## Testing

### Test Without Display:

The firmware will continue to work even if no display is connected. Commands will still be processed and logged to Serial Monitor.

### View Serial Output:

Open Arduino Serial Monitor (115200 baud) to see:

- BLE connection status
- All received commands
- Display update confirmations

### Test Commands:

From the mobile app:

1. Switch on D2 → Display shows "D2:ON"
2. Change LED color → Display shows "LED:r,g,b,brightness"
3. Move forward → Display shows "F"
4. Turn on horn → Display shows "HORN:ON"

## Code Structure

### Key Functions:

**updateDisplay(String command)**

- Updates OLED with received command
- Maintains history of last 3 commands
- Formats and displays text

**handleDigitalPinCommand(String command)**

- Parses commands like "D2:ON"
- Controls GPIO pins accordingly
- Updates display via updateDisplay()

**MyServerCallbacks::onConnect()**

- Called when device connects
- Shows "CONNECTED" on display

**MyServerCallbacks::onDisconnect()**

- Called when device disconnects
- Shows "DISCONNECTED" on display
- Clears command history

## Additional Notes

- Display updates happen instantly when commands are received
- Command history is cleared on disconnection
- Display will show "..." for commands longer than 16 characters
- The display uses minimal memory and doesn't affect BLE performance
- You can still use Serial Monitor alongside the display

## Future Enhancements (Optional)

You can extend the display functionality:

- Show battery level
- Display WiFi status
- Show sensor readings in real-time
- Add custom graphics/icons for different commands
- Implement scrolling for long command lists
- Add timestamp to each command
