// web/src/app/adapters/web-bluetooth.adapter.ts
import { Injectable } from '@angular/core';
import { CommunicationAdapter } from '@eps-lift-app/core-logic';
import { BehaviorSubject, from, Observable, of } from 'rxjs';
import { switchMap, tap } from 'rxjs/operators';

@Injectable()
export class WebBluetoothAdapter implements CommunicationAdapter {
  private device: BluetoothDevice | null = null;
  private server: BluetoothRemoteGATTServer | null = null;

  private readonly _connectionState$ = new BehaviorSubject<boolean>(false);
  readonly connectionState$: Observable<boolean> = this._connectionState$.asObservable();

  connect(deviceName: string): Observable<boolean> {
    console.log('[Web] Requesting Bluetooth device...');
    return from(navigator.bluetooth.requestDevice({
      filters: [{ namePrefix: deviceName }],
      optionalServices: [] // TODO: Укажите UUID вашего сервиса
    })).pipe(
      tap(device => {
        this.device = device;
        device.addEventListener('gattserverdisconnected', () => {
          this._connectionState$.next(false);
        });
      }),
      switchMap(device => from(device.gatt!.connect())),
      tap(server => {
        this.server = server;
        this._connectionState$.next(true);
        console.log('[Web] Connected!');
      }),
      switchMap(() => of(true))
    );
  }

  disconnect(): void {
    if (this.device?.gatt?.connected) {
      this.device.gatt.disconnect();
      this.server = null;
      this._connectionState$.next(false);
      console.log('[Web] Disconnected.');
    }
  }

  writeData(data: string): void {
    if (!this.server?.connected) {
        console.warn('[Web] Cannot write data: not connected.');
        return;
    }
    // TODO: Реализовать логику записи данных в характеристику
    console.log(`[Web] Writing data: ${data}`);
  }
}