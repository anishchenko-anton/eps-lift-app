import {
  ApplicationConfig,
  provideBrowserGlobalErrorListeners,
  provideZoneChangeDetection,
} from '@angular/core';
import { provideRouter } from '@angular/router';
import { appRoutes } from './app.routes';

import { CommunicationAdapter } from '@eps-lift-app/core-logic';
import { WebBluetoothAdapter } from './adapters/web-bluetooth.adapter';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(appRoutes),
    { provide: CommunicationAdapter, useClass: WebBluetoothAdapter }
  ],
};
