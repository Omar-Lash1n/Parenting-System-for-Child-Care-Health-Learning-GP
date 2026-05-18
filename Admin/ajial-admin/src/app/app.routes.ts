import { Routes } from '@angular/router';
import { HomeComponent } from './pages/home/home.component';
import { SpecialistsLayoutComponent } from './pages/specialists/specialists-layout/specialists-layout.component';
import { DashboardComponent as SpecialistsDashboardComponent } from './pages/specialists/dashboard/dashboard.component';
import { MainDashboard as SpecialistsMainDashboardComponent } from './pages/specialists/main-dashboard/main-dashboard';
import { ChildrenLayoutComponent } from './pages/children/children-layout/children-layout.component';
import { DashboardComponent as ChildrenDashboardComponent } from './pages/children/dashboard/dashboard.component';
import { ParentsLayoutComponent } from './pages/parents/parents-layout/parents-layout.component';
import { DashboardComponent as ParentsDashboardComponent } from './pages/parents/dashboard/dashboard.component';
import { DailyQuestionsLayoutComponent } from './pages/daily-questions/daily-questions-layout/daily-questions-layout.component';
import { QuestionsListComponent } from './pages/daily-questions/questions-list/questions-list.component';
import { CreateQuestionComponent } from './pages/daily-questions/create-question/create-question.component';
import { EditQuestionComponent } from './pages/daily-questions/edit-question/edit-question.component';
import { LessonsLayoutComponent } from './pages/lessons/lessons-layout/lessons-layout.component';
import { LessonsListComponent } from './pages/lessons/lessons-list/lessons-list.component';
import { CreateLessonComponent } from './pages/lessons/create-lesson/create-lesson.component';
import { EditLessonComponent } from './pages/lessons/edit-lesson/edit-lesson.component';
import { LessonCategoriesComponent } from './pages/lessons/categories/categories.component';

export const routes: Routes = [
    { path: '', component: HomeComponent, title: 'أجيال | الرئيسية' },
    { 
        path: 'specialists', 
        component: SpecialistsLayoutComponent,
        children: [
            { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
            { path: 'dashboard', component: SpecialistsMainDashboardComponent, title: 'أجيال | المتخصصين - إحصائيات' },
            { path: 'requests', component: SpecialistsDashboardComponent, title: 'أجيال | المتخصصين - طلبات' }
        ]
    },
    { 
        path: 'children', 
        component: ChildrenLayoutComponent,
        children: [
            { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
            { path: 'dashboard', component: ChildrenDashboardComponent, title: 'أجيال | الأطفال - إحصائيات' }
        ]
    },
    { 
        path: 'parents', 
        component: ParentsLayoutComponent,
        children: [
            { path: '', redirectTo: 'dashboard', pathMatch: 'full' },
            { path: 'dashboard', component: ParentsDashboardComponent, title: 'أجيال | الوالدين - إحصائيات' }
        ]
    },
    {
        path: 'daily-questions',
        component: DailyQuestionsLayoutComponent,
        children: [
            { path: '', component: QuestionsListComponent, title: 'أجيال | إدارة الأسئلة اليومية' },
            { path: 'create', component: CreateQuestionComponent, title: 'أجيال | إنشاء سؤال يومي' },
            { path: 'edit/:id', component: EditQuestionComponent, title: 'أجيال | تعديل سؤال يومي' }
        ]
    },
    {
        path: 'lessons',
        component: LessonsLayoutComponent,
        children: [
            { path: '', component: LessonsListComponent, title: 'أجيال | التغذية التربوية' },
            { path: 'create', component: CreateLessonComponent, title: 'أجيال | إنشاء درس' },
            { path: 'edit/:id', component: EditLessonComponent, title: 'أجيال | تعديل درس' },
            { path: 'categories', component: LessonCategoriesComponent, title: 'أجيال | إدارة التصنيفات' }
        ]
    },
    { path: '**', redirectTo: '' }
];
