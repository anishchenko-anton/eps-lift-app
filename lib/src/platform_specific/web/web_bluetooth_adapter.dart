import 'dart:async';
// import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart'; // Раскомментировать
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core_logic/adapters/communication_adapter.dart'; // Путь нужно будет поправить

/// Реализация адаптера для Web
/// Использует Web Bluetooth API через плагин (симуляция).
class WebBluetoothAdapter implements CommunicationAdapter {
  final _connectionStateController = StreamController<bool>.broadcast();
  
  @override
  Stream<bool> get connectionState => _connectionStateController.stream;

  // Симуляция для веба
  @override
  Stream<List<ScanResult>> get scanResults => Stream.value([]);
  @override
  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) async {}
  @override
  Future<void> stopScan() async {}
  @override
  Future<List<BluetoothService>> discoverServices() async => [];

  @override
  Future<bool> connect(BluetoothDevice device) async {
    print('WEB ADAPTER: Trying to connect to ${device.platformName}');
    await Future.delayed(const Duration(seconds: 1));
    _connectionStateController.add(true);
    print('WEB ADAPTER: Connected successfully');
    return true;
  }

  @override
  void disconnect() {
    print('WEB ADAPTER: Disconnecting');
    _connectionStateController.add(false);
  }

  @override
  void writeData(BluetoothCharacteristic characteristic, String data) {
     if (!_connectionStateController.hasListener || _connectionStateController.isClosed) return;
    print('WEB ADAPTER: Writing data: $data');
  }
  
  @override
  void dispose() {
    _connectionStateController.close();
  }
}