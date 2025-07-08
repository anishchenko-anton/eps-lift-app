// Файл: lib/src/ui/home_screen.dart
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../service_locator.dart';
import '../core_logic/facades/lift_control_facade.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final LiftControlFacade _facade;

  @override
  void initState() {
    super.initState();
    _facade = sl<LiftControlFacade>();
  }

  @override
  void dispose() {
    _facade.disconnect();
    _facade.dispose();
    super.dispose();
  }

  // Главный метод build, который теперь просто выбирает нужный макет
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление подъемником'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _facade.isConnected,
        builder: (context, isConnected, child) {
          if (isConnected) {
            return _buildConnectedLayout(); // Макет для ПОДКЛЮЧЕННОГО состояния
          } else {
            return _buildDisconnectedLayout(); // Макет для НЕПОДКЛЮЧЕННОГО состояния
          }
        },
      ),
    );
  }

  // --- Макет №1: Когда НЕ ПОДКЛЮЧЕНЫ ---
  Widget _buildDisconnectedLayout() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusSection(),
              const SizedBox(height: 24),
              _buildScanSection(),
              const SizedBox(height: 16),
              _buildDeviceListSection(),
              const SizedBox(height: 16),
              _buildServiceListSection(), // Список сервисов нужен только здесь
              const SizedBox(height: 32),
              // _buildControlPanel(), // Кнопки здесь выключены
            ],
          ),
        ),
      ),
    );
  }

  // --- Макет №2: Когда ПОДКЛЮЧЕНЫ ---
  Widget _buildConnectedLayout() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Верхняя часть
          _buildStatusSection(),
          const SizedBox(height: 24),
          _buildScanSection(), // Здесь будет кнопка "Отключиться"

          // Распорки для центрирования
          const Spacer(),
          _buildControlPanel(), // Кнопки здесь включены
          const Spacer(),
        ],
      ),
    );
  }

  // --- Вспомогательные виджеты (остаются почти без изменений) ---

  Widget _buildStatusSection() {
    return ValueListenableBuilder<String>(
      valueListenable: _facade.statusMessage,
      builder: (context, message, child) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        );
      },
    );
  }

  Widget _buildScanSection() {
    return ValueListenableBuilder<bool>(
      valueListenable: _facade.isConnected,
      builder: (context, isConnected, child) {
        if (isConnected) {
          return ElevatedButton(
            onPressed: _facade.disconnect,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Отключиться'),
          );
        } else {
          return ValueListenableBuilder<bool>(
            valueListenable: _facade.isScanning,
            builder: (context, isScanning, child) {
              return ElevatedButton(
                onPressed: isScanning ? _facade.stopScan : _facade.startScan,
                child: Text(isScanning ? 'Остановить поиск' : 'Найти устройства'),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildDeviceListSection() {
    return StreamBuilder<List<ScanResult>>(
      stream: _facade.scanResults,
      initialData: const [],
      builder: (c, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final result = snapshot.data![index];
              final deviceName = result.device.platformName.isNotEmpty ? result.device.platformName : 'Неизвестное устройство';
              return ListTile(
                title: Text(deviceName),
                subtitle: Text(result.device.remoteId.toString()),
                trailing: Text('${result.rssi} dBm'),
                onTap: () => _facade.connect(result.device),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildServiceListSection() {
    return ValueListenableBuilder<List<BluetoothService>>(
      valueListenable: _facade.discoveredServices,
      builder: (context, services, child) {
        // Скрываем, если характеристика выбрана ИЛИ сервисов нет
        if (services.isEmpty || _facade.selectedCharacteristic.value != null) {
          return const SizedBox.shrink();
        }
        return Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return ExpansionTile(
                title: Text('Сервис: ${_getShortUuid(service.uuid)}'),
                children: service.characteristics.map((c) => _buildCharacteristicTile(c)).toList(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCharacteristicTile(BluetoothCharacteristic c) {
    final bool canWrite = c.properties.write || c.properties.writeWithoutResponse;
    return ListTile(
      title: Text('Характеристика: ${_getShortUuid(c.uuid)}'),
      subtitle: Text('Свойства: ${c.properties}'),
      trailing: canWrite ? const Icon(Icons.radio_button_unchecked) : null,
      onTap: canWrite ? () => _facade.selectedCharacteristic.value = c : null,
      tileColor: !canWrite ? Colors.grey.shade200 : null,
    );
  }

  String _getShortUuid(Guid uuid) {
    final uuidString = uuid.toString().toUpperCase();
    return uuidString.length > 8 ? uuidString.substring(4, 8) : uuidString;
  }

  Widget _buildControlPanel() {
    return ValueListenableBuilder<BluetoothCharacteristic?>(
      valueListenable: _facade.selectedCharacteristic,
      builder: (context, selectedC, child) {
        final bool isEnabled = selectedC != null;

        final buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.green, // Основной цвет - зеленый
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(24),
        // Цвет "наложения" при взаимодействии
        // overlayColor: MaterialStateProperty.resolveWith<Color?>(
        //   (Set<MaterialState> states) {
        //     // Если кнопка в состоянии "нажата"
        //     if (states.contains(MaterialState.pressed)) {
        //       return Colors.red; // Возвращаем красный цвет
        //     }
        //     return null; // В остальных случаях - стандартное поведение
        //   },
        // ),
      );

        

        return AbsorbPointer(
          absorbing: !isEnabled,
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Важно для центрирования
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTapDown: (_) {HapticFeedback.lightImpact(); _facade.moveUp(); },
                  onTapUp: (_) => _facade.stop(),
                  onTapCancel: () => _facade.stop(),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: buttonStyle,
                    // style: ElevatedButton.styleFrom(
                    // shape: const CircleBorder(),      // Делаем кнопку круглой
                    // padding: const EdgeInsets.all(24), // Увеличиваем размер
                    // ),
                  //  child: const Text('Вверх')
                  child: const Icon(Icons.arrow_upward, size: 150, color: Colors.black)
                  )
                  
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTapDown: (_) {HapticFeedback.lightImpact(); _facade.moveDown(); } ,
                  onTapUp: (_) => _facade.stop(),
                  onTapCancel: () => _facade.stop(),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: buttonStyle,
                  //  child: const Text('Вниз')
                   child: const Icon(Icons.arrow_downward, size: 150, color: Colors.black,)
                   ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}