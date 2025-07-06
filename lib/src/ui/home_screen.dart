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

  String _getShortUuid(Guid uuid) {
    final uuidString = uuid.toString().toUpperCase();
    if (uuidString.length > 8) {
      return uuidString.substring(4, 8);
    }
    return uuidString;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление подъемником'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Center(
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
                _buildServiceListSection(),
                const SizedBox(height: 32),
                _buildControlPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
        return ValueListenableBuilder<bool>(
          valueListenable: _facade.isConnected,
          builder: (context, isConnected, child) {
            if (isConnected || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              height: 200,
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
      },
    );
  }
  
  Widget _buildServiceListSection() {
    return ValueListenableBuilder<List<BluetoothService>>(
      valueListenable: _facade.discoveredServices,
      builder: (context, services, child) {
        if (services.isEmpty) {
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
    return ValueListenableBuilder<BluetoothCharacteristic?>(
      valueListenable: _facade.selectedCharacteristic,
      builder: (context, selectedC, child) {
        final bool canWrite = c.properties.write || c.properties.writeWithoutResponse;
        return ListTile(
          title: Text('Характеристика: ${_getShortUuid(c.uuid)}'),
          subtitle: Text('Свойства: ${c.properties}'),
          trailing: canWrite
              ? (selectedC == c
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.radio_button_unchecked))
              : null,
          onTap: canWrite
              ? () {
                  _facade.selectedCharacteristic.value = c;
                }
              : null,
          tileColor: !canWrite ? Colors.grey.shade200 : null,
        );
      },
    );
  }

  Widget _buildControlPanel() {
    return ValueListenableBuilder<BluetoothCharacteristic?>(
      valueListenable: _facade.selectedCharacteristic,
      builder: (context, selectedC, child) {
        final bool isEnabled = selectedC != null;
        return AbsorbPointer(
          absorbing: !isEnabled,
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTapDown: (_) => _facade.moveUp(),
                  onTapUp: (_) => _facade.stop(),
                  onTapCancel: () => _facade.stop(),
                  child: ElevatedButton(onPressed: () {}, child: const Text('Вверх')),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTapDown: (_) => _facade.moveDown(),
                  onTapUp: (_) => _facade.stop(),
                  onTapCancel: () => _facade.stop(),
                  child: ElevatedButton(onPressed: () {}, child: const Text('Вниз')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
