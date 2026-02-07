# Wasserwaage App

Flutter-App für die digitale Wasserwaage. Verbindet sich per Bluetooth Low Energy mit dem ESP32 und zeigt die Neigung in Echtzeit an.

## Voraussetzungen

- [Flutter](https://flutter.dev/docs/get-started/install) installiert
- ESP32 mit dem Wasserwaage-Sketch (MPU6050 + BLE)
- Android-Smartphone oder iPhone

## Installation

1. Flutter SDK im PATH oder Projektordner öffnen

2. Abhängigkeiten installieren:
   ```
   flutter pub get
   ```

3. **Projekt initialisieren** (erzeugt fehlende Platform-Dateien wie App-Icon, Gradle-Konfiguration):
   ```
   flutter create .
   ```
   Dies fügt fehlende Dateien hinzu, ohne deinen Code zu überschreiben.

## Ausführen

### Android
```
flutter run
```
Oder in Android Studio / VS Code starten.

### iOS
```
flutter run
```
Hinweis: Für iOS wird ein Mac und Xcode benötigt.

## Berechtigungen

- **Android**: BLUETOOTH_SCAN, BLUETOOTH_CONNECT, ACCESS_FINE_LOCATION (werden automatisch angefordert)
- **iOS**: Bluetooth-Nutzung (Text in Info.plist hinterlegt)

## Nutzung

1. ESP32 einschalten (Wasserwaage-Sketch muss laufen)
2. App öffnen
3. Auf „Wasserwaage suchen“ tippen
4. „Wasserwaage“ in der Liste auswählen
5. Nach der Verbindung erscheint die Wasserwaagen-Anzeige mit den Neigungswinkeln

## Projektstruktur

- `lib/main.dart` – App mit BLE-Verbindung und UI
- `Wasserwage_ESP32/` – Arduino-Sketch für den ESP32
