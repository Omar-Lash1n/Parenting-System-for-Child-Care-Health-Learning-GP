import { Routes } from '@angular/router';
import { HomeComponent } from './pages/home/home.component';
import { SpecialistsLayoutComponent } from './pages/specialists/specialists-layout/specialists-layout.component';
import { DashboardComponent as SpecialistsDashboardComponent } from './pages/specialists/dashboard/dashboard.component';
import { MainDashboard as SpecialistsMainDashboardComponent } from './pages/specialists/main-dashboard/main-dashboard';
import { ChildrenLayoutComponent } from './pages/children/children-layout/children-layout.component';
import { DashboardComponent as ChildrenDashboardComponent } from './pages/children/dashboard/dashboard.component';
import { ParentsLayoutComponent } from './pages/parents/parents-layout/parents-layout.component';
import { DashboardComponent as ParentsDashboardComponent } from './pages/parents/dashboard/dashboard.component';

export const routes: Routes = [
    { path: '', component: HomeComponent },
    { 
        path: 'specialists', 
        component: SpecialistsLayoutComponent,
        children: [
            { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
            { path: 'dashboard', component: SpecialistsMainDashboardComponent },
            { path: 'requests', component: SpecialistsDashboardComponent }
        ]
    },
    { 
        path: 'children', 
        component: ChildrenLayoutComponent,
        children: [
            { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
            { path: 'dashboard', component: ChildrenDashboardComponent }
        ]
    },
    { 
        path: 'parents', 
        component: ParentsLayoutComponent,
        children: [
            { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
            { path: 'dashboard', component: ParentsDashboardComponent }
        ]
    },
    { path: '**', redirectTo: '' }
];
