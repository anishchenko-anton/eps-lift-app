// libs/core-logic/src/lib/state/lift-control.facade.ts
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { tap, catchError, finalize } from 'rxjs/operators';
import { LiftDeviceService } from '../services/lift-device.service';

@Injectable({
  providedIn: 'root',
})
export class LiftControlFacade {
  private readonly _isConnecting$ = new BehaviorSubject<boolean>(false);
  private readonly _connectionError$ = new BehaviorSubject<string | null>(null);

  public readonly isConnecting$: Observable<boolean> = this._isConnecting$.asObservable();
  public readonly connectionError$: Observable<string | null> = this._connectionError$.asObservable();

  constructor(private liftDeviceService: LiftDeviceService) {}

  public get isConnected$(): Observable<boolean> {
    return this.liftDeviceService.connectionState$;
  }
  
  public moveUp(): void {
    this.liftDeviceService.moveUp();
  }

  public moveDown(): void {
    this.liftDeviceService.moveDown();
  }

  public stop(): void {
    this.liftDeviceService.stop();
  }

  public connect(deviceName: string): void {
    this._isConnecting$.next(true);
    this._connectionError$.next(null);

    this.liftDeviceService.connect(deviceName).pipe(
      tap(() => {
        // Логика после успешного подключения, если нужна
      }),
      catchError((error) => {
        console.error('Connection failed:', error);
        this._connectionError$.next('Не удалось подключиться к устройству.');
        return of(false);
      }),
      finalize(() => this._isConnecting$.next(false))
    ).subscribe();
  }

  public disconnect(): void {
    this.liftDeviceService.disconnect();
  }
}