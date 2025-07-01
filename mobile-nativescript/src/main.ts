// mobile-nativescript/src/main.ts
import { bootstrapApplication } from '@angular/platform-browser';
import { AppComponent } from './app.component';
import { appRoutes } from './app.routes';
import { provideRouter } from '@angular/router';

// --- ИМПОРТЫ ДЛЯ НАШЕЙ АРХИТЕКТУРЫ ---
import { CommunicationAdapter } from '@eps-lift-app/core-logic';
import { NativescriptBluetoothAdapter } from './adapters/nativescript-bluetooth.adapter';

// --- ПРАВИЛЬНЫЙ ИМПОРТ ДЛЯ HTTP-КЛИЕНТА ---
import { provideHttpClient } from '@angular/common/http';


bootstrapApplication(AppComponent, {
  providers: [
    provideRouter(appRoutes),
    provideHttpClient(), // <-- ИСПОЛЬЗУЕМ СТАНДАРТНЫЙ ПРОВАЙДЕР

    // --- НАШ ПРОВАЙДЕР ДЛЯ АДАПТЕРА ОСТАЕТСЯ БЕЗ ИЗМЕНЕНИЙ ---
    { provide: CommunicationAdapter, useClass: NativescriptBluetoothAdapter }
  ],
});