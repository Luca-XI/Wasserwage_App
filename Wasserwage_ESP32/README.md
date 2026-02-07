# Wasserwaage ESP32 – BLE + MPU6050

ESP32-Programm für die Wasserwaage. Sendet Neigungsdaten per Bluetooth Low Energy an die App.

## Hardware

- **ESP32** (mit eingebautem Bluetooth)
- **MPU6050** (6-Achsen Beschleunigungs-/Gyro-Sensor)

### Verdrahtung

| MPU6050 | ESP32  |
|---------|--------|
| VCC     | 3.3V   |
| GND     | GND    |
| SDA     | GPIO 21|
| SCL     | GPIO 22|

## Benötigte Software

### Arduino IDE

1. [Arduino IDE](https://www.arduino.cc/en/software) installieren
2. ESP32-Board-Unterstützung hinzufügen:
   - **Datei** → **Einstellungen** → **Zusätzliche Boardverwalter-URLs**:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
   - **Werkzeuge** → **Board** → **Boardverwalter** → „esp32“ suchen und installieren

### Bibliotheken

Über **Sketch** → **Bibliothek einbinden** → **Bibliotheken verwalten** installieren:

| Bibliothek | Suche |
|------------|-------|
| Adafruit MPU6050 | `Adafruit MPU6050` |
| Adafruit Unified Sensor | `Adafruit Unified Sensor` |
| Adafruit BusIO | `Adafruit BusIO` |

## Hochladen

1. ESP32 per USB verbinden
2. **Werkzeuge** → **Board** → **ESP32 Arduino** → dein Modell (z.B. „ESP32 Dev Module“)
3. **Werkzeuge** → **Port** → richtigen COM-Port wählen
4. **Sketch** → **Hochladen**

## Datenformat

Die App erhält über BLE im Format:

```
X:12.34,Y:-5.67
```

- **X**: Neigung links/rechts (Grad)
- **Y**: Neigung vor/zurück (Grad)

## BLE Service

- **Service UUID**: `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **Characteristic UUID** (Neigung): `beb5483e-36e1-4688-b7f5-ea07361b26a8`
- **Gerätename**: `Wasserwaage`

## Nächster Schritt

Flutter-App entwickeln, die sich mit diesem BLE-Service verbindet und die Wasserwaage anzeigt.
