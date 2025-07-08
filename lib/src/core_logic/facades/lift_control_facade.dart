import 'dart:async';
import 'package:flutter/foundation.dart'; // Для ValueNotifier
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core_logic/services/lift_device_service.dart'; 
/// Фасад для UI.
/// Управляет состоянием и предоставляет простой API для виджетов.
/// 
class LiftControlFacade {
  final LiftDeviceService _liftDeviceService;
  late final StreamSubscription _connectionStateSubscription;

  /// Notifier для состояния подключения. UI будет его слушать.
  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  /// Notifier для отображения статуса в UI.
  final ValueNotifier<String> statusMessage = ValueNotifier("Готов к подключению");
  final ValueNotifier<bool> isScanning = ValueNotifier(false);

  final ValueNotifier<List<BluetoothService>> discoveredServices = ValueNotifier([]);
  /// Выбранная пользователем характеристика для записи
  final ValueNotifier<BluetoothCharacteristic?> selectedCharacteristic = ValueNotifier(null);

  LiftControlFacade(this._liftDeviceService) {
    // Подписываемся на поток состояния подключения из сервиса
    _connectionStateSubscription = _liftDeviceService.connectionState.listen((state) {
      isConnected.value = state;
      if (!state) {
          statusMessage.value = "Отключено";
      }
    });
  }

  Stream<List<ScanResult>> get scanResults => _liftDeviceService.scanResults;

  Future<void> startScan() async {
    isScanning.value = true;
    statusMessage.value = "Поиск устройств...";
    await _liftDeviceService.startScan();
    isScanning.value = false;
    statusMessage.value = "Поиск завершен.";
  }
  
  Future<void> stopScan() async {
    await _liftDeviceService.stopScan();
    isScanning.value = false;
    statusMessage.value = "Поиск остановлен.";
  }

  /// Подключение к устройству.
  Future<void> connect(BluetoothDevice device) async {
    if (isConnected.value) return;
    isScanning.value = false;
    await _liftDeviceService.stopScan();
    statusMessage.value = "Подключение к ${device.platformName}...";
    try {
      final success = await _liftDeviceService.connect(device);
      if (!success) {
        statusMessage.value = "Не удалось подключиться.";
        return;
      }

      statusMessage.value = "Подключено. Обнаружение сервисов...";
      final services = await _liftDeviceService.discoverServices();
      discoveredServices.value = services; // Сразу обновляем список для UI

      if (services.isEmpty) {
        statusMessage.value = "Подключено, но сервисы не найдены.";
        return;
      }

      // Ищем все характеристики, которые поддерживают запись.
      final List<BluetoothCharacteristic> writableCharacteristics = [];
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            writableCharacteristics.add(characteristic);
          }
        }
      }

      // Анализируем результат.
      if (writableCharacteristics.length == 1) {
        // Если нашлась только одна — выбираем ее автоматически.
        selectedCharacteristic.value = writableCharacteristics.first;
        statusMessage.value = "Готов к работе (характеристика выбрана автоматически)";
        print("FACADE: Auto-selected the only writable characteristic.");
      } else if (writableCharacteristics.length > 1) {
        // Если нашлось несколько — просим пользователя выбрать.
        statusMessage.value = "Найдено несколько характеристик. Выберите нужную.";
         print("FACADE: Found multiple writable characteristics. Waiting for user selection.");
      } else {
        // Если не нашлось ни одной.
        statusMessage.value = "Подключено, но нет характеристик для управления.";
        print("FACADE: No writable characteristics found.");
      }

    } catch (e) {
      statusMessage.value = "Ошибка подключения: ${e.toString()}";
    }
  }

  /// Отключение.
  void disconnect() {
    _liftDeviceService.disconnect();
  }

  /// Команды движения.
  void moveUp() {
    if (selectedCharacteristic.value == null) return;
    _liftDeviceService.moveUp(selectedCharacteristic.value!);
  }
  void moveDown() {
    if (selectedCharacteristic.value == null) return;
    _liftDeviceService.moveDown(selectedCharacteristic.value!);
  }
  void stop() {
    if (selectedCharacteristic.value == null) return;
    _liftDeviceService.stop(selectedCharacteristic.value!);
  }

  /// Освобождение ресурсов.
  void dispose() {
    _connectionStateSubscription.cancel();
    _liftDeviceService.dispose();
    isConnected.dispose();
    statusMessage.dispose();
    isScanning.dispose();
    discoveredServices.dispose();
    selectedCharacteristic.dispose();
  }
}