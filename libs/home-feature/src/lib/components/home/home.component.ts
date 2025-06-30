// libs/home-feature/src/lib/components/home/home.component.ts
import { Component, ChangeDetectionStrategy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LiftControlFacade } from '@eps-lift-app/core-logic';

@Component({
  selector: 'eps-lift-app-home',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './home.component.html',
  styleUrls: ['./home.component.scss'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class HomeComponent {
  // Компонент ничего не знает о Bluetooth.
  // Он общается только с фасадом, который предоставляет ему состояние и методы.
  constructor(public facade: LiftControlFacade) {}

  connect() {
    this.facade.connect('MyLiftDevice');
  }

  // Методы для mousedown/mouseup в вебе
  onPress(direction: 'up' | 'down') {
    if (direction === 'up') {
      this.facade.moveUp();
    } else {
      this.facade.moveDown();
    }
  }

  onRelease() {
    this.facade.stop();
  }

  // Метод для tap в NativeScript (более простой сценарий)
  onTap(direction: 'up' | 'down' | 'stop') {
    switch (direction) {
      case 'up':
        this.facade.moveUp();
        break;
      case 'down':
        this.facade.moveDown();
        break;
      case 'stop':
        this.facade.stop();
        break;
    }
  }
}