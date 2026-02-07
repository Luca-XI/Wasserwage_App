/*
 * Wasserwaage - ESP32 BLE + MPU6050
 * 
 * Sendet Neigungsdaten per Bluetooth Low Energy an die App.
 * 
 * Benötigte Bibliotheken:
 * - Adafruit MPU6050
 * - Adafruit Unified Sensor
 * - Adafruit BusIO
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

// === Konfiguration ===
#define BLE_DEVICE_NAME "Wasserwaage"
#define SEND_INTERVAL_MS 100   // Alle 100ms senden
#define MPU6050_SDA 21
#define MPU6050_SCL 22

// === Globale Variablen ===
Adafruit_MPU6050 mpu;
BLEServer* pServer = nullptr;
BLECharacteristic* pTiltCharacteristic = nullptr;
bool deviceConnected = false;
bool oldDeviceConnected = false;
unsigned long lastSendTime = 0;

// BLE UUIDs
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define TILT_CHAR_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Callback wenn ein Gerät verbindet/trennt
class MyServerCallbacks: public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
  }
  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
  }
};

void setup() {
  Serial.begin(115200);
  Serial.println("Wasserwaage startet...");

  // MPU6050 initialisieren
  Wire.begin(MPU6050_SDA, MPU6050_SCL);
  
  if (!mpu.begin()) {
    Serial.println("Fehler: MPU6050 nicht gefunden!");
    Serial.println("Prüfe Verdrahtung (SDA=21, SCL=22, VCC=3.3V, GND=GND)");
    while (1) {
      delay(1000);
    }
  }
  
  mpu.setAccelerometerRange(MPU6050_RANGE_2_G);
  mpu.setGyroRange(MPU6050_RANGE_250_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_5_HZ);
  
  Serial.println("MPU6050 bereit");

  // BLE initialisieren
  BLEDevice::init(BLE_DEVICE_NAME);
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);
  pTiltCharacteristic = pService->createCharacteristic(
    TILT_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ   |
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pTiltCharacteristic->addDescriptor(new BLE2902());
  pService->start();

  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("BLE bereit - Gerät heißt: " BLE_DEVICE_NAME);
  Serial.println("Jetzt mit der App verbinden!");
}

void loop() {
  // Verbindungswiederherstellung nach Trennung
  if (!deviceConnected && oldDeviceConnected) {
    delay(500);
    pServer->startAdvertising();
    Serial.println("Warte auf neue Verbindung...");
    oldDeviceConnected = deviceConnected;
  }
  if (deviceConnected && !oldDeviceConnected) {
    oldDeviceConnected = deviceConnected;
  }

  // Daten senden wenn verbunden und Intervall abgelaufen
  if (deviceConnected && (millis() - lastSendTime >= SEND_INTERVAL_MS)) {
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    // Neigungswinkel aus Accelerometer berechnen (in Grad)
    // atan2 gibt Winkel relativ zur Vertikalen
    float angleX = atan2(a.acceleration.y, sqrt(a.acceleration.x * a.acceleration.x + a.acceleration.z * a.acceleration.z)) * 180.0 / PI;
    float angleY = atan2(-a.acceleration.x, sqrt(a.acceleration.y * a.acceleration.y + a.acceleration.z * a.acceleration.z)) * 180.0 / PI;

    // Als String senden: "X:12.34,Y:-5.67"
    char dataBuffer[32];
    snprintf(dataBuffer, sizeof(dataBuffer), "X:%.2f,Y:%.2f", angleX, angleY);

    pTiltCharacteristic->setValue(dataBuffer);
    pTiltCharacteristic->notify();

    Serial.printf("Gesendet: %s\n", dataBuffer);

    lastSendTime = millis();
  }

  delay(10);
}
