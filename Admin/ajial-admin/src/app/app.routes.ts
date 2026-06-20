import { Routes } from '@angular/router';
import { HomeComponent } from './pages/home/home.component';
import { SpecialistsLayoutComponent } from './pages/specialists/specialists-layout/specialists-layout.component';
import { DashboardComponent as SpecialistsDashboardComponent } from './pages/specialists/dashboard/dashboard.component';
import { MainDashboard as SpecialistsMainDashboardComponent } from './pages/specialists/main-dashboard/main-dashboard';
import { RatingsComponent as SpecialistRatingsComponent } from './pages/specialists/ratings/ratings.component';
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
import { RankingLayoutComponent } from './pages/ranking/ranking-layout/ranking-layout.component';
import { RankingCurrentComponent } from './pages/ranking/ranking-current/ranking-current.component';
import { RankingHistoryComponent } from './pages/ranking/ranking-history/ranking-history.component';
import { ClinicsLayoutComponent } from './pages/clinics/clinics-layout/clinics-layout.component';
import { ClinicsDashboardComponent } from './pages/clinics/clinics-dashboard/clinics-dashboard.component';
import { RemoteConsultationsDashboardComponent } from './pages/clinics/remote-consultations-dashboard/remote-consultations-dashboard.component';
import { ConsultationPaymentsLayoutComponent } from './pages/consultation-payments/consultation-payments-layout/consultation-payments-layout.component';
import { PaymentsDashboardComponent } from './pages/consultation-payments/payments-dashboard/payments-dashboard.component';
import { PaymentSettingsComponent } from './pages/consultation-payments/payment-settings/payment-settings.component';

export const routes: Routes = [
    { path: '', component: HomeComponent, title: 'أجيال | الرئيسية' },
    { 
        path: 'specialists', 
        component: SpecialistsLayoutComponent,
        children: [
            { path: '', redirectTo: 'requests', pathMatch: 'full' },
            { path: 'requests', component: SpecialistsDashboardComponent, title: 'أجيال | المتخصصين - طلبات' },
            { path: 'ratings', component: SpecialistRatingsComponent, title: 'أجيال | المتخصصين - تقييمات الجلسات' }
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
    {
        path: 'ranking',
        component: RankingLayoutComponent,
        children: [
            { path: '', component: RankingCurrentComponent, title: 'أجيال | الترتيب الحالي' },
            { path: 'history', component: RankingHistoryComponent, title: 'أجيال | سجل المواسم' }
        ]
    },
    {
        path: 'clinics',
        component: ClinicsLayoutComponent,
        children: [
            { path: '', redirectTo: 'list', pathMatch: 'full' },
            { path: 'list', component: ClinicsDashboardComponent, title: 'أجيال | إدارة العيادات' },
            { path: 'remote', component: RemoteConsultationsDashboardComponent, title: 'أجيال | الاستشارات عن بُعد' }
        ]
    },
    {
        path: 'consultation-payments',
        component: ConsultationPaymentsLayoutComponent,
        children: [
            { path: '', redirectTo: 'list', pathMatch: 'full' },
            { path: 'list', component: PaymentsDashboardComponent, title: 'أجيال | مراجعة المدفوعات' },
            { path: 'settings', component: PaymentSettingsComponent, title: 'أجيال | إعدادات الدفع' }
        ]
    },
    { path: '**', redirectTo: '' }
];
