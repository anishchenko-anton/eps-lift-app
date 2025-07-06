// Сервис для управления устройством-подъемником.
/// Инкапсулирует прямые вызовы к адаптеру.
 import 'package:flutter_blue_plus/flutter_blue_plus.dart';
 
 import '../../core_logic/adapters/communication_adapter.dart'; 

class LiftDeviceService {
  final CommunicationAdapter _adapter;

  LiftDeviceService(this._adapter);

  /// Поток состояния подключения, проксируется из адаптера.
  Stream<bool> get connectionState => _adapter.connectionState;
  Stream<List<ScanResult>> get scanResults => _adapter.scanResults;
  
  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) => _adapter.startScan(timeout: timeout);
  
  Future<void> stopScan() => _adapter.stopScan();

  /// Подключение к устройству.
  Future<bool> connect(BluetoothDevice device) {
    return _adapter.connect(device);
  }

  /// Обнаружение сервисов
  Future<List<BluetoothService>> discoverServices() => _adapter.discoverServices();

  /// Отключение от устройства.
  void disconnect() {
    _adapter.disconnect();
  }

  /// Команда: двигаться вверх.
  void moveUp(BluetoothCharacteristic characteristic) {
    print('SERVICE: Sending command MOVE_UP');
    _adapter.writeData(characteristic, 'mu:1');
  }

  /// Команда: двигаться вниз.
  void moveDown(BluetoothCharacteristic characteristic) {
    print('SERVICE: Sending command MOVE_DOWN');
    _adapter.writeData(characteristic, 'md:1');
  }

  /// Команда: стоп.
  void stop(BluetoothCharacteristic characteristic) {
    print('SERVICE: Sending command STOP');
    _adapter.writeData(characteristic, 'stop');
  }
  
  void dispose() {
    _adapter.dispose();
  }
}