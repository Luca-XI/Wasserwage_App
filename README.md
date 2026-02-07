# Wasserwaage – Digitale Wasserwaage mit ESP32

Digitale Wasserwaage mit ESP32, MPU6050-Sensor und Flutter-App für iPhone, Android und Web.

## Projektüberblick

```
ESP32 (MPU6050 + BLE) ←→ App (Flutter)
```

- **ESP32** mit MPU6050 misst die Neigung und sendet Daten per Bluetooth Low Energy
- **Flutter-App** verbindet sich per BLE, zeigt die Wasserwaage an und unterstützt Kalibrierung

## Inhaltsverzeichnis

| Ordner | Beschreibung |
|--------|--------------|
| `Wasserwage_ESP32/` | Arduino-Sketch für ESP32 + MPU6050 |
| `wasserwage_app/` | Flutter-App (Android, iOS, Web) |
| `discord_pull.example.sh` | Beispiel-Skript für Discord-Benachrichtigungen bei Updates |

## Schnellstart

### 1. ESP32 vorbereiten

1. Sketch `Wasserwage_ESP32/Wasserwage_ESP32.ino` in der Arduino IDE öffnen
2. Bibliotheken installieren: Adafruit MPU6050, Adafruit Unified Sensor, Adafruit BusIO
3. MPU6050 anschließen (SDA→21, SCL→22, VCC→3.3V, GND→GND)
4. Sketch auf ESP32 hochladen

### 2. App starten

```bash
cd wasserwage_app
flutter pub get
flutter run -d chrome   # oder: flutter run (für Android/iPhone)
```

### 3. Verbinden

1. ESP32 einschalten
2. In der App „Wasserwaage suchen“ tippen
3. Gerät auswählen und verbinden
4. Optional: „Kalibrieren“ drücken, um die aktuelle Position als 0° zu setzen

## Voraussetzungen

- **ESP32** mit MPU6050
- **Flutter SDK** (für die App)
- **Bluetooth** (am Handy oder im Browser bei Web-Version)

## Discord-Benachrichtigungen (optional)

Für Benachrichtigungen bei Git-Updates (z.B. auf dem Raspberry Pi):

1. `discord_pull.example.sh` zu `discord_pull.sh` kopieren
2. Discord-Webhook-URL in `discord_pull.sh` eintragen
3. Skript ausführbar machen: `chmod +x discord_pull.sh`
4. Regelmäßig ausführen (z.B. per Cron) oder nach `git pull`

## Lizenz

Projekt für private und Bildungszwecke.
