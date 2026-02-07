import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// BLE UUIDs vom ESP32
const String serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
const String tiltCharUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
const String deviceName = 'Wasserwaage';

void main() {
  runApp(const WasserwaageApp());
}

class WasserwaageApp extends StatelessWidget {
  const WasserwaageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wasserwaage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
      ),
      home: const WasserwaageScreen(),
    );
  }
}

class WasserwaageScreen extends StatefulWidget {
  const WasserwaageScreen({super.key});

  @override
  State<WasserwaageScreen> createState() => _WasserwaageScreenState();
}

class _WasserwaageScreenState extends State<WasserwaageScreen> {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _tiltChar;
  StreamSubscription<List<int>>? _subscription;
  Timer? _pollingTimer;
  
  double _angleX = 0;
  double _angleY = 0;
  double _offsetX = 0;
  double _offsetY = 0;
  bool _isConnected = false;
  bool _isScanning = false;
  String _statusMessage = 'Bluetooth einschalten und ESP32 in Reichweite bringen';
  List<ScanResult> _scanResults = [];

  @override
  void dispose() {
    _subscription?.cancel();
    _pollingTimer?.cancel();
    _disconnect();
    super.dispose();
  }

  Future<void> _checkBluetooth() async {
    if (await FlutterBluePlus.isSupported == false) {
      setState(() => _statusMessage = 'Bluetooth wird nicht unterstützt');
      return;
    }
    if (await FlutterBluePlus.isOn == false) {
      setState(() => _statusMessage = 'Bitte Bluetooth einschalten');
      return;
    }
    _startScan();
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Suche nach Wasserwaage...';
      _scanResults = [];
    });

    FlutterBluePlus.startScan(
      withNames: [deviceName],
      withServices: [Guid(serviceUuid)],  // Für Web Bluetooth: Services vorab angeben
      timeout: const Duration(seconds: 15),
    );

    FlutterBluePlus.scanResults.listen((results) {
      setState(() => _scanResults = results);
    });

    await Future.delayed(const Duration(seconds: 15));
    FlutterBluePlus.stopScan();
    
    setState(() => _isScanning = false);
    
    if (_scanResults.isEmpty) {
      setState(() => _statusMessage = 'Wasserwaage nicht gefunden. ESP32 eingeschaltet?');
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    try {
      await FlutterBluePlus.stopScan();
      setState(() => _statusMessage = 'Verbinde...');
      await device.connect(timeout: const Duration(seconds: 15));
      
      List<BluetoothService> services = await device.discoverServices();
      
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == tiltCharUuid.toLowerCase()) {
              _tiltChar = char;
              bool usePolling = false;
              // Web Bluetooth: Notifications liefern oft keine Daten, daher immer Polling
              if (kIsWeb) {
                usePolling = true;
                _startPolling();
              } else {
                try {
                  await _tiltChar!.setNotifyValue(true).timeout(
                    const Duration(seconds: 3),
                  );
                  _subscription = _tiltChar!.lastValueStream.listen(_onDataReceived);
                } catch (_) {
                  usePolling = true;
                  _startPolling();
                }
              }
              
              setState(() {
                _device = device;
                _isConnected = true;
                _statusMessage = usePolling ? 'Verbunden (Polling)' : 'Verbunden';
              });
              return;
            }
          }
        }
      }
      await device.disconnect();
      setState(() => _statusMessage = 'Wasserwaage-Service nicht gefunden');
    } catch (e) {
      setState(() => _statusMessage = 'Verbindung fehlgeschlagen: $e');
    }
  }

  void _startPolling() async {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 80), (_) async {
      if (_tiltChar == null) return;
      try {
        List<int> value = await _tiltChar!.read();
        _onDataReceived(value);
      } catch (_) {}
    });
  }

  void _onDataReceived(List<int> data) {
    if (data.isEmpty) return;
    try {
      String value = String.fromCharCodes(data).trim();
      // Format: "X:12.34,Y:-5.67" (evtl. mit Steuerzeichen)
      RegExp exp = RegExp(r'X:([-\d.]+),Y:([-\d.]+)');
      var match = exp.firstMatch(value);
      if (match != null && mounted) {
        final x = double.tryParse(match.group(1) ?? '0') ?? 0;
        final y = double.tryParse(match.group(2) ?? '0') ?? 0;
        setState(() {
          _angleX = x;
          _angleY = y;
        });
      }
    } catch (_) {}
  }

  void _calibrate() {
    setState(() {
      _offsetX = _angleX;
      _offsetY = _angleY;
    });
  }

  Future<void> _disconnect() async {
    _subscription?.cancel();
    _subscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _tiltChar = null;
    if (_device != null) {
      await _device!.disconnect();
      _device = null;
    }
    setState(() {
      _isConnected = false;
      _angleX = 0;
      _angleY = 0;
      _offsetX = 0;
      _offsetY = 0;
      _statusMessage = 'Getrennt';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wasserwaage'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.link_off),
              onPressed: _disconnect,
              tooltip: 'Trennen',
            ),
          IconButton(
            icon: const Icon(Icons.bluetooth_searching),
            onPressed: _isScanning ? null : _checkBluetooth,
            tooltip: 'Suchen',
          ),
        ],
      ),
      body: _isConnected ? _buildLevelView() : _buildConnectView(),
    );
  }

  Widget _buildConnectView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth,
              size: 80,
              color: _isScanning ? Colors.blue : Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            if (_scanResults.isNotEmpty) ...[
              const Text('Gefundene Geräte:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _scanResults.length,
                  itemBuilder: (context, i) {
                    var r = _scanResults[i];
                    return ListTile(
                      leading: const Icon(Icons.sensors),
                      title: Text(r.device.platformName.isNotEmpty ? r.device.platformName : 'Wasserwaage'),
                      subtitle: Text(r.device.remoteId.toString()),
                      onTap: () => _connect(r.device),
                    );
                  },
                ),
              ),
            ] else if (!_isScanning)
              FilledButton.icon(
                onPressed: _checkBluetooth,
                icon: const Icon(Icons.search),
                label: const Text('Wasserwaage suchen'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelView() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            _statusMessage,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.green),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: _WasserwaageDisplay(
                angleX: _angleX - _offsetX,
                angleY: _angleY - _offsetY,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AngleCard(label: 'X', value: _angleX - _offsetX),
                _AngleCard(label: 'Y', value: _angleY - _offsetY),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: FilledButton.icon(
              onPressed: _calibrate,
              icon: const Icon(Icons.tune),
              label: const Text('Kalibrieren'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WasserwaageDisplay extends StatelessWidget {
  final double angleX;
  final double angleY;

  const _WasserwaageDisplay({required this.angleX, required this.angleY});

  @override
  Widget build(BuildContext context) {
    // Bubble position: -1 bis 1, 0 = mittig
    double bubbleX = (angleX / 15).clamp(-1.0, 1.0);
    double bubbleY = (angleY / 15).clamp(-1.0, 1.0);
    
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Äußerer Kreis (Rahmen)
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[800]!, width: 4),
              color: Colors.grey[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          // Innenfläche mit Wasser-Füllung (grün/transparent)
          Positioned(
            left: 20,
            top: 20,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green[50],
                border: Border.all(color: Colors.green[200]!, width: 2),
              ),
            ),
          ),
          // Horizontale und vertikale Linien (Null-Linien)
          Positioned(
            left: 135,
            top: 20,
            child: Container(width: 2, height: 240, color: Colors.grey[400]),
          ),
          Positioned(
            left: 20,
            top: 135,
            child: Container(width: 240, height: 2, color: Colors.grey[400]),
          ),
          // Bubble (bewegt sich mit Neigung)
          Positioned(
            left: 130 + bubbleX * 90,
            top: 130 + bubbleY * 90,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green[700],
                border: Border.all(color: Colors.green[900]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AngleCard extends StatelessWidget {
  final String label;
  final double value;

  const _AngleCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            Text(
              '${value.toStringAsFixed(2)}°',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
