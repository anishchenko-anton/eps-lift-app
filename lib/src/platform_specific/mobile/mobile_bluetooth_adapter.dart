import 'dart:async';
import 'dart:convert'; // Для utf8
import 'package:flutter_blue_plus/flutter_blue_plus.dart'; 
import '../../core_logic/adapters/communication_adapter.dart';

/// Реализация адаптера для мобильных платформ (Android, iOS)
/// Использует плагин flutter_blue_plus.
class MobileBluetoothAdapter implements CommunicationAdapter {
  final _connectionStateController = StreamController<bool>.broadcast();
  
  BluetoothDevice? _connectedDevice;
  // BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  // StreamSubscription<List<ScanResult>>? _scanSubscription;


  @override
  Stream<bool> get connectionState => _connectionStateController.stream;

  @override
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  @override
  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) async {
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception("Bluetooth не поддерживается на этом устройстве");
    }
    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
    }
    return FlutterBluePlus.startScan(timeout: timeout);
  }

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  Future<bool> connect(BluetoothDevice device) async {
    _connectedDevice = device;
    
    _connectionStateSubscription = _connectedDevice!.connectionState.listen((state) {
      final isConnected = state == BluetoothConnectionState.connected;
      _connectionStateController.add(isConnected);
    });

    try {
      await _connectedDevice!.connect();
      return true;
    } catch (e) {
      print("Ошибка подключения в адаптере: $e");
      return false;
    }
  }

  @override
  Future<List<BluetoothService>> discoverServices() async {
    if (_connectedDevice == null) return [];
    return await _connectedDevice!.discoverServices();
  }


  @override
  void disconnect() async {
    await _connectionStateSubscription?.cancel();
    _connectionStateSubscription = null;
    await _connectedDevice?.disconnect();
    _connectedDevice = null;

    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(false);
    }

  }

  @override
  void writeData(BluetoothCharacteristic characteristic, String data) async {
    try {
      final canWriteWithoutResponse = characteristic.properties.writeWithoutResponse;
      final canWrite = characteristic.properties.write;

      if (canWriteWithoutResponse) {
        await characteristic.write(utf8.encode(data), withoutResponse: true);
        print('MOBILE ADAPTER: Успешно отправлены данные (без ответа): $data');
      } else if (canWrite) {
        await characteristic.write(utf8.encode(data), withoutResponse: false);
        print('MOBILE ADAPTER: Успешно отправлены данные (с ответом): $data');
      } else {
        print('MOBILE ADAPTER: Ошибка: Характеристика не поддерживает запись.');
      }
    } catch (e) {
      print('MOBILE ADAPTER: Ошибка при отправке данных: $e');
    }
  }
  
  @override
  void dispose() {
    disconnect();
    _connectionStateController.close();
  }
}