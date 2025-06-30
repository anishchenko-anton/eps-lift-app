// mobile-nativescript/src/app/adapters/nativescript-bluetooth.adapter.ts
import { Injectable } from '@angular/core';
import { CommunicationAdapter } from '@eps-lift-app/core-logic';
import { BehaviorSubject, Observable, of } from 'rxjs';
// TODO: Установить плагин: ns plugin add @nativescript-community/bluetooth
// import { Bluetooth, Peripheral } from '@nativescript-community/bluetooth';

@Injectable()
export class NativescriptBluetoothAdapter implements CommunicationAdapter {
  // private readonly bluetooth = new Bluetooth();
  // private connectedDevice: Peripheral | null = null;

  private readonly _connectionState$ = new BehaviorSubject<boolean>(false);
  readonly connectionState$: Observable<boolean> = this._connectionState$.asObservable();

  connect(deviceName: string): Observable<boolean> {
    console.log(`[NativeScript] Connecting to ${deviceName}...`);
    // TODO: Реализовать логику подключения через nativescript-bluetooth
    // Для примера просто имитируем успех
    this._connectionState$.next(true);
    return of(true);
  }

  disconnect(): void {
    console.log('[NativeScript] Disconnecting...');
    // TODO: Реализовать логику отключения
    this._connectionState$.next(false);
  }

  writeData(data: string): void {
    if (!this._connectionState$.value) {
      console.warn('[NativeScript] Cannot write data: not connected.');
      return;
    }
    console.log(`[NativeScript] Writing data: ${data}`);
  }
}