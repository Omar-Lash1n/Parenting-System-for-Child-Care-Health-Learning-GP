import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Observable, finalize } from 'rxjs';
import { ApiResponse, DailyQuestionListDto } from '../../../models/daily-question.model';
import { DailyQuestionsService } from '../../../services/daily-questions.service';
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
  selector: 'app-questions-list',
  standalone: true,
  imports: [CommonModule, RouterLink, ConfirmDialogComponent, LoadingSpinnerComponent, StatusBadgeComponent],
  templateUrl: './questions-list.component.html',
  styleUrl: './questions-list.component.scss'
})
export class QuestionsListComponent implements OnInit {
  private service = inject(DailyQuestionsService);
  private cdr = inject(ChangeDetectorRef);
  private toastTimer: ReturnType<typeof setTimeout> | null = null;

  questions: DailyQuestionListDto[] = [];
  loading = false;
  error: string | null = null;
  filterActive: boolean | null = null;
  actionLoading: Record<string, boolean> = {};
  resetting = false;
  dialogConfig: DialogConfig | null = null;
  toast: { message: string; type: 'success' | 'error' | 'warning' } | null = null;

  ngOnInit() {
    this.fetchQuestions();
  }

  fetchQuestions() {
    this.loading = true;
    this.error = null;

    this.service.getAll(this.filterActive ?? undefined).pipe(
      finalize(() => {
        this.loading = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        if (res.success) {
          this.questions = res.data ?? [];
        } else {
          this.error = res.message || 'تعذر تحميل الأسئلة اليومية';
        }
      },
      error: () => {
        this.error = 'حدث خطأ أثناء تحميل الأسئلة اليومية';
      }
    });
  }

  setFilter(value: boolean | null) {
    this.filterActive = value;
    this.fetchQuestions();
  }

  confirmActivate(question: DailyQuestionListDto) {
    this.dialogConfig = {
      title: 'تفعيل السؤال',
      message: 'تفعيل هذا السؤال سيؤدي إلى إلغاء تفعيل السؤال النشط الحالي. هل تريد المتابعة؟',
      confirmText: 'تفعيل',
      type: 'warning',
      action: () => this.activateQuestion(question.id)
    };
  }

  confirmDeactivate(question: DailyQuestionListDto) {
    this.dialogConfig = {
      title: 'إلغاء تفعيل السؤال',
      message: 'إلغاء تفعيل هذا السؤال يعني عدم ظهور سؤال يومي للأهل. هل تريد المتابعة؟',
      confirmText: 'إلغاء التفعيل',
      type: 'warning',
      action: () => this.deactivateQuestion(question.id)
    };
  }

  confirmDelete(question: DailyQuestionListDto) {
    const activeMessage = question.isActive ? ' هذا السؤال نشط حاليا، وحذفه سيزيل السؤال اليومي الحالي.' : '';
    this.dialogConfig = {
      title: 'حذف السؤال',
      message: `هل أنت متأكد من حذف هذا السؤال؟ لا يمكن التراجع عن هذه العملية.${activeMessage}`,
      confirmText: 'حذف',
      type: 'danger',
      action: () => this.deleteQuestion(question.id)
    };
  }

  confirmResetAll() {
    this.dialogConfig = {
      title: 'إلغاء تفعيل كل الأسئلة',
      message: 'سيتم إلغاء تفعيل كل الأسئلة، ولن يظهر أي سؤال يومي للأهل. هل أنت متأكد؟',
      confirmText: 'إلغاء تفعيل الكل',
      type: 'danger',
      action: () => this.resetAllQuestions()
    };
  }

  handleDialogClose(confirmed: boolean) {
    const action = this.dialogConfig?.action;
    this.dialogConfig = null;

    if (confirmed && action) {
      action();
    }
  }

  activateQuestion(id: string) {
    this.runQuestionAction(id, () => this.service.activate(id), 'تم تفعيل السؤال بنجاح');
  }

  deactivateQuestion(id: string) {
    this.runQuestionAction(id, () => this.service.deactivate(id), 'تم إلغاء تفعيل السؤال بنجاح');
  }

  deleteQuestion(id: string) {
    this.runQuestionAction(id, () => this.service.delete(id), 'تم حذف السؤال بنجاح');
  }

  resetAllQuestions() {
    this.resetting = true;
    this.service.resetAll().pipe(
      finalize(() => {
        this.resetting = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        if (res.success) {
          this.showToast('تم إلغاء تفعيل كل الأسئلة', 'success');
          this.fetchQuestions();
        } else {
          this.showToast(res.message || 'تعذر تنفيذ العملية', 'error');
        }
      },
      error: () => this.showToast('حدث خطأ أثناء تنفيذ العملية', 'error')
    });
  }

  correctPercentage(question: DailyQuestionListDto): number {
    if (question.totalAnswers === 0) {
      return 0;
    }

    return Math.round((question.correctAnswers / question.totalAnswers) * 100);
  }

  trackByQuestionId(_index: number, question: DailyQuestionListDto): string {
    return question.id;
  }

  private runQuestionAction<T>(id: string, request: () => Observable<ApiResponse<T>>, successMessage: string) {
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
          this.fetchQuestions();
        } else {
          this.showToast(res.message || 'تعذر تنفيذ العملية', 'error');
        }
      },
      error: () => this.showToast('حدث خطأ أثناء تنفيذ العملية', 'error')
    });
  }

  private showToast(message: string, type: 'success' | 'error' | 'warning') {
    this.toast = { message, type };

    if (this.toastTimer) {
      clearTimeout(this.toastTimer);
    }

    this.toastTimer = setTimeout(() => {
      this.toast = null;
      this.toastTimer = null;
      this.cdr.detectChanges();
    }, 3000);

    this.cdr.detectChanges();
  }
}
