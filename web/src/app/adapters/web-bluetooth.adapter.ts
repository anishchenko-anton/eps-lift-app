// web/src/app/adapters/web-bluetooth.adapter.ts
import { Injectable, NgZone } from '@angular/core';
import { CommunicationAdapter, LiftControlFacade } from '@eps-lift-app/core-logic';
import { BehaviorSubject, from, Observable, of, throwError } from 'rxjs';
import { catchError, finalize, switchMap, tap } from 'rxjs/operators';

// !!! ВАЖНО: Замените эти значения на реальные UUID вашего устройства !!!
const LIFT_SERVICE_UUID = '0000ffe0-0000-1000-8000-00805f9b34fb'; // Пример: UART Service
const LIFT_CHARACTERISTIC_UUID = '0000ffe1-0000-1000-8000-00805f9b34fb'; // Пример: TX/RX Characteristic

@Injectable()
export class WebBluetoothAdapter implements CommunicationAdapter {
  private device: BluetoothDevice | null = null;
  private server: BluetoothRemoteGATTServer | null = null;
  private characteristic: BluetoothRemoteGATTCharacteristic | null = null;
  private textEncoder = new TextEncoder(); // Кодировщик для преобразования строки в байты

  private readonly _connectionState$ = new BehaviorSubject<boolean>(false);
  readonly connectionState$: Observable<boolean> = this._connectionState$.asObservable();

  constructor(private ngZone: NgZone) {}

  connect(deviceName: string): Observable<boolean> {
    console.log('[Web] Requesting Bluetooth device...');
    return from(
      navigator.bluetooth.requestDevice({
        filters: [{ namePrefix: deviceName }],
        optionalServices: [LIFT_SERVICE_UUID], // Указываем, какой сервис нам нужен
      })
    ).pipe(
      // Подключаемся к GATT-серверу устройства
      switchMap((device) => {
        this.device = device;
        // Запускаем обработчик отключения внутри зоны Angular, чтобы UI обновлялся
        this.device.addEventListener('gattserverdisconnected', () => {
          this.ngZone.run(() => {
            this.handleDisconnect();
          });
        });
        return from(device.gatt!.connect());
      }),
      // Получаем нужный нам сервис
      switchMap((server) => {
        this.server = server;
        return from(server.getPrimaryService(LIFT_SERVICE_UUID));
      }),
      // Получаем нужную нам характеристику
      switchMap((service) => {
        return from(service.getCharacteristic(LIFT_CHARACTERISTIC_UUID));
      }),
      // Сохраняем характеристику и сообщаем об успехе
      tap((characteristic) => {
        this.characteristic = characteristic;
        this._connectionState$.next(true);
        console.log('[Web] Successfully connected and characteristic is ready.');
      }),
      // Преобразуем в Observable<boolean>
      switchMap(() => of(true)),
      catchError((error) => {
        console.error('[Web] Connection failed:', error);
        return throwError(() => new Error('Failed to connect via Web Bluetooth.'));
      })
    );
  }

  disconnect(): void {
    if (this.device?.gatt?.connected) {
      this.device.gatt.disconnect();
    } else {
      // Если устройство не подключено, просто сбрасываем состояние
      this.handleDisconnect();
    }
  }

  writeData(data: string): void {
    if (!this.characteristic) {
      console.warn('[Web] Cannot write data: characteristic not available.');
      return;
    }
    // Преобразуем строку в ArrayBuffer и отправляем на устройство
    const
     encodedData = this.textEncoder.encode(data);
    from(this.characteristic.writeValueWithResponse(encodedData)).subscribe({
      next: () => console.log(`[Web] Data written successfully: ${data}`),
      error: (err) => console.error('[Web] Error writing data:', err),
    });
  }

  private handleDisconnect(): void {
    this.device = null;
    this.server = null;
    this.characteristic = null;
    this._connectionState$.next(false);
    console.log('[Web] Disconnected.');
  }
}