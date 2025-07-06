import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // kIsWeb - глобальная константа для определения платформы

// Импортируем все наши классы
import 'src/core_logic/adapters/communication_adapter.dart';
import 'src/core_logic/services/lift_device_service.dart';
import 'src/core_logic/facades/lift_control_facade.dart';
import 'src/platform_specific/mobile/mobile_bluetooth_adapter.dart';
import 'src/platform_specific/web/web_bluetooth_adapter.dart';

final sl = GetIt.instance; // sl - service locator

void setupLocator() {
  // Регистрируем адаптер в зависимости от платформы
  if (kIsWeb) {
    // Если это веб, используем WebBluetoothAdapter
    sl.registerLazySingleton<CommunicationAdapter>(() => WebBluetoothAdapter());
    print("Service Locator: Registered WebBluetoothAdapter");
  } else {
    // Иначе (Android, iOS, Desktop) используем MobileBluetoothAdapter
    sl.registerLazySingleton<CommunicationAdapter>(() => MobileBluetoothAdapter());
    print("Service Locator: Registered MobileBluetoothAdapter");
  }

  // Регистрируем сервисы, которые зависят от CommunicationAdapter.
  // get_it автоматически найдет и подставит нужную реализацию.
  sl.registerLazySingleton(() => LiftDeviceService(sl<CommunicationAdapter>()));

  // Фасад лучше регистрировать как Factory, чтобы для каждого экрана (если их будет много)
  // создавался свой экземпляр, который можно будет корректно уничтожить (dispose).
  sl.registerFactory(() => LiftControlFacade(sl<LiftDeviceService>()));
}