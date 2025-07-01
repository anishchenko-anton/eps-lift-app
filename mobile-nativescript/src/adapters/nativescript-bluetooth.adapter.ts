// mobile-nativescript/src/app/adapters/nativescript-bluetooth.adapter.ts
import { Injectable, NgZone } from '@angular/core';
import { CommunicationAdapter } from '@eps-lift-app/core-logic';
import { BehaviorSubject, Observable, from, throwError, timer, of } from 'rxjs';
import { catchError, filter, switchMap, take, tap } from 'rxjs/operators';
import { Bluetooth, Peripheral } from '@nativescript-community/ble';

// !!! ВАЖНО: Замените эти значения на реальные UUID вашего устройства !!!
const LIFT_SERVICE_UUID = '0000ffe0-0000-1000-8000-00805f9b34fb'; // Пример: UART Service
const LIFT_CHARACTERISTIC_UUID = '0000ffe1-0000-1000-8000-00805f9b34fb'; // Пример: TX/RX Characteristic

@Injectable()
export class NativescriptBluetoothAdapter implements CommunicationAdapter {
  private readonly bluetooth = new Bluetooth();
  private connectedDevice: Peripheral | null = null;

  private readonly _connectionState$ = new BehaviorSubject<boolean>(false);
  readonly connectionState$: Observable<boolean> = this._connectionState$.asObservable();

  constructor(private ngZone: NgZone) {}

  connect(deviceName: string): Observable<boolean> {
    const discoveredDevice$ = new BehaviorSubject<Peripheral | null>(null);

    return from(
      this.bluetooth.startScanning({
        filters: [{ serviceUUID: LIFT_SERVICE_UUID }],
        seconds: 5, // Сканируем 5 секунд
        onDiscovered: (peripheral) => {
          console.log(`[NS] Found peripheral: ${peripheral.name} (${peripheral.UUID})`);
          if (peripheral.name?.toLowerCase().includes(deviceName.toLowerCase())) {
            discoveredDevice$.next(peripheral);
          }
        },
      })
    ).pipe(
      // Ждем, пока сканирование не найдет наше устройство
      switchMap(() => timer(5000).pipe(take(1))), // Даем сканеру время отработать
      switchMap(() => {
        if (!discoveredDevice$.value) {
          return throwError(() => new Error(`Device with name ${deviceName} not found.`));
        }
        this.bluetooth.stopScanning();
        return of(discoveredDevice$.value);
      }),
      // Подключаемся к найденному устройству
      switchMap((peripheral) => {
        return from(
          this.bluetooth.connect({
            UUID: peripheral.UUID,
            onConnected: (p) => {
              this.ngZone.run(() => {
                console.log('[NS] Connected!');
                this.connectedDevice = p;
                this._connectionState$.next(true);
              });
            },
            onDisconnected: () => {
              this.ngZone.run(() => {
                console.log('[NS] Disconnected!');
                this.connectedDevice = null;
                this._connectionState$.next(false);
              });
            },
          })
        );
      }),
      // Преобразуем в Observable<boolean>
      switchMap(() => of(true)),
      catchError((error) => {
        console.error('[NS] Connection failed:', error);
        return throwError(() => new Error('Failed to connect via NativeScript Bluetooth.'));
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
      console.warn('[NS] Cannot write data: not connected.');
      return;
    }
    // В NativeScript данные нужно отправлять как Hex-строку или ArrayBuffer
    const value = this.stringToHex(data);

    from(
      this.bluetooth.write({
        peripheralUUID: this.connectedDevice.UUID,
        serviceUUID: LIFT_SERVICE_UUID,
        characteristicUUID: LIFT_CHARACTERISTIC_UUID,
        value: value,
      })
    ).subscribe({
      next: () => console.log(`[NS] Data written successfully: ${data}`),
      error: (err) => console.error('[NS] Error writing data:', err),
    });
  }

  private stringToHex(str: string): string {
    let hex = '';
    for (let i = 0; i < str.length; i++) {
      hex += '' + str.charCodeAt(i).toString(16);
    }
    return hex;
  }
}