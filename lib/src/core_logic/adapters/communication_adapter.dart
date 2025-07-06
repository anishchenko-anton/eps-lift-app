import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Абстрактный класс CommunicationAdapter
/// Определяет контракт для взаимодействия с физическим устройством.
/// Ядро логики зависит только от этой абстракции.
abstract class CommunicationAdapter {
  /// Поток состояния подключения (true - подключено, false - нет).
  Stream<bool> get connectionState;
  Stream<List<ScanResult>> get scanResults;

  /// Метод для подключения к устройству по его имени.
  /// Возвращает Future<bool>, который завершается успешно (true), если подключение удалось.
  Future<bool> connect(BluetoothDevice device);
  Future<void> startScan({Duration timeout});
  Future<void> stopScan();


  Future<List<BluetoothService>> discoverServices();

  /// Метод для отключения от устройства.
  void disconnect();

  /// Метод для отправки данных (команд) на устройство.
  void writeData(BluetoothCharacteristic characteristic, String data);
  
  /// Метод для освобождения ресурсов.
  void dispose();
}