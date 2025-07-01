// mobile-nativescript/src/app/adapters/nativescript-bluetooth.adapter.ts
import { Injectable, NgZone } from '@angular/core';
import { CommunicationAdapter } from '@eps-lift-app/core-logic';
import { BehaviorSubject, from, Observable, of, throwError, timer } from 'rxjs';
import { catchError, switchMap, take, tap } from 'rxjs/operators';
import { Bluetooth, Peripheral } from '@nativescript-community/ble';

// !!! ВАЖНО: Замените эти значения на реальные UUID вашего устройства !!!
const LIFT_SERVICE_UUID = '0000ffe0-0000-1000-8000-00805f9b34fb'; // Пример: UART Service
const LIFT_CHARACTERISTIC_UUID = '0000ffe1-0000-1000-8000-00805f9b34fb'; // Пример: TX/RX Characteristic

@Injectable()
export class NativescriptBluetoothAdapter implements CommunicationAdapter {
  private readonly bluetooth = new Bluetooth(); // 5-секундный таймаут для команд
  private connectedDevice: Peripheral | null = null;

  private readonly _connectionState$ = new BehaviorSubject<boolean>(false);
  readonly connectionState$: Observable<boolean> = this._connectionState$.asObservable();

  constructor(private ngZone: NgZone) {}

  connect(deviceName: string): Observable<boolean> {
    const discoveredDevice$ = new BehaviorSubject<Peripheral | null>(null);

    return from(this.bluetooth.startScanning({
      filters: [{ serviceUUID: LIFT_SERVICE_UUID }], // Ищем устройства только с нашим сервисом
      seconds: 5,                       // Сканируем 5 секунд
      onDiscovered: (peripheral) => {
        console.log(`[NS] Найдено устройство: ${peripheral.name} (${peripheral.UUID})`);
        // Проверяем, совпадает ли имя (или его часть)
        if (peripheral.name?.toLowerCase().includes(deviceName.toLowerCase())) {
          discoveredDevice$.next(peripheral);
        }
      },
    })).pipe(
      // Даем сканеру время отработать и найти устройство
      switchMap(() => timer(5100).pipe(take(1))),
      switchMap(() => {
        this.bluetooth.stopScanning();
        // Если устройство не найдено, выбрасываем ошибку
        if (!discoveredDevice$.value) {
          return throwError(() => new Error(`Устройство с именем '${deviceName}' не найдено.`));
        }
        return of(discoveredDevice$.value);
      }),
      // Подключаемся к найденному устройству
      switchMap((peripheral) => from(this.bluetooth.connect({
        UUID: peripheral.UUID,
        onConnected: (p) => this.ngZone.run(() => this.handleConnect(p)),
        onDisconnected: () => this.ngZone.run(() => this.handleDisconnect()),
      }))),
      // Возвращаем true в случае успеха
      switchMap(() => of(true)),
      catchError((error) => {
        console.error('[NS] Ошибка подключения:', error);
        return throwError(() => new Error('Не удалось подключиться через NativeScript Bluetooth.'));
      })
    );
  }

  disconnect(): void {
    if (this.connectedDevice) {
      from(this.bluetooth.disconnect({ UUID: this.connectedDevice.UUID })).subscribe();
    }
  }

  writeData(data: string): void {
    if (!this.connectedDevice) {
      console.warn('[NS] Не могу отправить данные: нет подключения.');
      return;
    }
    // Отправляем команду на устройство
    from(this.bluetooth.write({
      peripheralUUID: this.connectedDevice.UUID,
      serviceUUID: LIFT_SERVICE_UUID,
      characteristicUUID: LIFT_CHARACTERISTIC_UUID,
      value: data, // Для многих устройств достаточно строки, для некоторых нужен ArrayBuffer
    })).subscribe({
      next: () => console.log(`[NS] Данные успешно отправлены: ${data}`),
      error: (err) => console.error('[NS] Ошибка при отправке данных:', err),
    });
  }

  private handleConnect(peripheral: Peripheral): void {
    console.log('[NS] Успешно подключено!');
    this.connectedDevice = peripheral;
    this._connectionState$.next(true);
  }

  private handleDisconnect(): void {
    console.log('[NS] Соединение разорвано!');
    this.connectedDevice = null;
    this._connectionState$.next(false);
  }
}