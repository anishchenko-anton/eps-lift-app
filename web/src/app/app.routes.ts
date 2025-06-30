import { Route } from '@angular/router';

import { HomeComponent } from '@home/src/lib/components/home/home.component';

export const appRoutes: Route[] = [
  {
    path: '',
    component: HomeComponent,
    pathMatch: 'full'
  },
];
