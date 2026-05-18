import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Observable, finalize } from 'rxjs';
import { ApiResponse, LessonAdminListDto, LessonCategoryDto } from '../../../models/lesson.model';
import { LessonsService } from '../../../services/lessons.service';
import { ConfirmDialogComponent, ConfirmDialogType } from '../../../shared/components/confirm-dialog/confirm-dialog.component';
import { LoadingSpinnerComponent } from '../../../shared/components/loading-spinner/loading-spinner.component';
import { StatusBadgeComponent } from '../../../shared/components/status-badge/status-badge.component';

interface DialogConfig {
  title: string;
  message: string;
  confirmText: string;
  type: ConfirmDialogType;
  action: () => void;
}

@Component({
  selector: 'app-lessons-list',
  standalone: true,
  imports: [CommonModule, RouterLink, ConfirmDialogComponent, LoadingSpinnerComponent, StatusBadgeComponent],
  templateUrl: './lessons-list.component.html',
  styleUrl: './lessons-list.component.scss'
})
export class LessonsListComponent implements OnInit {
  private service = inject(LessonsService);
  private cdr = inject(ChangeDetectorRef);
  private toastTimer: ReturnType<typeof setTimeout> | null = null;

  lessons: LessonAdminListDto[] = [];
  categories: LessonCategoryDto[] = [];
  loading = false;
  error: string | null = null;
  filterActive: boolean | null = null;
  filterCategoryId = '';
  actionLoading: Record<string, boolean> = {};
  dialogConfig: DialogConfig | null = null;
  toast: { message: string; type: 'success' | 'error' | 'warning' } | null = null;

  ngOnInit() {
    this.loadCategories();
    this.fetchLessons();
  }

  loadCategories() {
    this.service.getCategories().subscribe({
      next: (res) => {
        if (res.success) this.categories = res.data ?? [];
        this.cdr.detectChanges();
      },
      error: () => {}
    });
  }

  fetchLessons() {
    this.loading = true;
    this.error = null;

    this.service.getLessons(
      this.filterCategoryId || undefined,
      this.filterActive ?? undefined
    ).pipe(
      finalize(() => {
        this.loading = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        if (res.success) {
          this.lessons = res.data ?? [];
        } else {
          this.error = res.message || 'تعذر تحميل الدروس';
        }
      },
      error: () => {
        this.error = 'حدث خطأ أثناء تحميل الدروس';
      }
    });
  }

  setFilter(value: boolean | null) {
    this.filterActive = value;
    this.fetchLessons();
  }

  onCategoryChange(event: Event) {
    this.filterCategoryId = (event.target as HTMLSelectElement).value;
    this.fetchLessons();
  }

  confirmActivate(lesson: LessonAdminListDto) {
    this.dialogConfig = {
      title: 'تفعيل الدرس',
      message: 'هل تريد تفعيل هذا الدرس؟',
      confirmText: 'تفعيل',
      type: 'warning',
      action: () => this.activateLesson(lesson.id)
    };
  }

  confirmDeactivate(lesson: LessonAdminListDto) {
    this.dialogConfig = {
      title: 'إلغاء تفعيل الدرس',
      message: 'هل تريد إلغاء تفعيل هذا الدرس؟',
      confirmText: 'إلغاء التفعيل',
      type: 'warning',
      action: () => this.deactivateLesson(lesson.id)
    };
  }

  confirmDelete(lesson: LessonAdminListDto) {
    this.dialogConfig = {
      title: 'حذف الدرس',
      message: 'هل أنت متأكد من حذف هذا الدرس؟ لا يمكن التراجع عن هذه العملية.',
      confirmText: 'حذف',
      type: 'danger',
      action: () => this.deleteLesson(lesson.id)
    };
  }

  handleDialogClose(confirmed: boolean) {
    const action = this.dialogConfig?.action;
    this.dialogConfig = null;
    if (confirmed && action) action();
  }

  activateLesson(id: string) {
    this.runAction(id, () => this.service.activateLesson(id), 'تم تفعيل الدرس بنجاح');
  }

  deactivateLesson(id: string) {
    this.runAction(id, () => this.service.deactivateLesson(id), 'تم إلغاء تفعيل الدرس بنجاح');
  }

  deleteLesson(id: string) {
    this.runAction(id, () => this.service.deleteLesson(id), 'تم حذف الدرس بنجاح');
  }

  trackById(_index: number, item: { id: string }): string {
    return item.id;
  }

  private runAction<T>(id: string, request: () => Observable<ApiResponse<T>>, successMessage: string) {
    this.actionLoading[id] = true;

    request().pipe(
      finalize(() => {
        this.actionLoading[id] = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        if (res.success) {
          this.showToast(successMessage, 'success');
          this.fetchLessons();
        } else {
          this.showToast(res.message || 'تعذر تنفيذ العملية', 'error');
        }
      },
      error: () => this.showToast('حدث خطأ أثناء تنفيذ العملية', 'error')
    });
  }

  private showToast(message: string, type: 'success' | 'error' | 'warning') {
    this.toast = { message, type };
    if (this.toastTimer) clearTimeout(this.toastTimer);
    this.toastTimer = setTimeout(() => {
      this.toast = null;
      this.toastTimer = null;
      this.cdr.detectChanges();
    }, 3000);
    this.cdr.detectChanges();
  }
}
