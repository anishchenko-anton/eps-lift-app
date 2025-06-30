// libs/core-logic/src/lib/services/lift-device.service.ts
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { CommunicationAdapter } from '../adapters/communication.adapter';

// Определим константы для команд для большей читаемости
const LIFT_COMMANDS = {
  MOVE_UP: 'CMD_UP',
  MOVE_DOWN: 'CMD_DOWN',
  STOP: 'CMD_STOP',
};

@Injectable({
  providedIn: 'root',
})
export class LiftDeviceService {
  // Сервис зависит от АБСТРАКЦИИ, а не от конкретной реализации.
  constructor(private communicationAdapter: CommunicationAdapter) {}

  public get connectionState$(): Observable<boolean> {
    return this.communicationAdapter.connectionState$;
  }

  public connect(deviceName: string): Observable<boolean> {
    return this.communicationAdapter.connect(deviceName);
  }

  public disconnect(): void {
    this.communicationAdapter.disconnect();
  }

  public moveUp(): void {
    console.log('Sending command: MOVE_UP');
    this.communicationAdapter.writeData(LIFT_COMMANDS.MOVE_UP);
  }

  public moveDown(): void {
    console.log('Sending command: MOVE_DOWN');
    this.communicationAdapter.writeData(LIFT_COMMANDS.MOVE_DOWN);
  }

  public stop(): void {
    console.log('Sending command: STOP');
    this.communicationAdapter.writeData(LIFT_COMMANDS.STOP);
  }
}