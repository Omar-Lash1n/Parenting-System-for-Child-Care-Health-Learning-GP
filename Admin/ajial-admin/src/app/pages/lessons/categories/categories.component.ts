import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { ReactiveFormsModule, UntypedFormBuilder, UntypedFormGroup, Validators } from '@angular/forms';
import { finalize } from 'rxjs';
import { LessonCategoryDto } from '../../../models/lesson.model';
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
  selector: 'app-lesson-categories',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, ConfirmDialogComponent, LoadingSpinnerComponent, StatusBadgeComponent],
  templateUrl: './categories.component.html',
  styleUrl: './categories.component.scss'
})
export class LessonCategoriesComponent implements OnInit {
  private service = inject(LessonsService);
  private fb = inject(UntypedFormBuilder);
  private cdr = inject(ChangeDetectorRef);
  private toastTimer: ReturnType<typeof setTimeout> | null = null;

  categories: LessonCategoryDto[] = [];
  loading = false;
  error: string | null = null;
  creating = false;
  editingId: string | null = null;
  editSaving = false;
  dialogConfig: DialogConfig | null = null;
  toast: { message: string; type: 'success' | 'error' | 'warning' } | null = null;

  createForm: UntypedFormGroup = this.fb.group({
    nameAr: ['', [Validators.required]],
    nameEn: [''],
    orderIndex: [1, [Validators.required, Validators.min(1)]]
  });

  editForm: UntypedFormGroup = this.fb.group({
    nameAr: ['', [Validators.required]],
    nameEn: [''],
    orderIndex: [1, [Validators.required, Validators.min(1)]],
    isActive: [true]
  });

  ngOnInit() {
    this.fetchCategories();
  }

  fetchCategories() {
    this.loading = true;
    this.error = null;

    this.service.getCategories().pipe(
      finalize(() => {
        this.loading = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        if (res.success) this.categories = res.data ?? [];
        else this.error = res.message || 'تعذر تحميل التصنيفات';
      },
      error: () => { this.error = 'حدث خطأ أثناء تحميل التصنيفات'; }
    });
  }

  submitCreate() {
    if (this.createForm.invalid) {
      this.createForm.markAllAsTouched();
      return;
    }

    this.creating = true;
    const value = this.createForm.getRawValue();

    this.service.createCategory({
      nameAr: String(value.nameAr).trim(),
      nameEn: value.nameEn?.trim() || null,
      orderIndex: Number(value.orderIndex)
    }).pipe(
      finalize(() => {
        this.creating = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        if (res.success) {
          this.showToast('تم إنشاء التصنيف بنجاح', 'success');
          this.createForm.reset({ nameAr: '', nameEn: '', orderIndex: 1 });
          this.fetchCategories();
        } else {
          this.showToast(res.message || 'تعذر إنشاء التصنيف', 'error');
        }
      },
      error: () => this.showToast('حدث خطأ أثناء إنشاء التصنيف', 'error')
    });
  }

  startEdit(category: LessonCategoryDto) {
    this.editingId = category.id;
    this.editForm.patchValue({
      nameAr: category.nameAr,
      nameEn: category.nameEn || '',
      orderIndex: category.orderIndex,
      isActive: category.isActive
    });
  }

  cancelEdit() {
    this.editingId = null;
  }

  submitEdit() {
    if (this.editForm.invalid || !this.editingId) {
      this.editForm.markAllAsTouched();
      return;
    }

    this.editSaving = true;
    const id = this.editingId;
    const value = this.editForm.getRawValue();

    this.service.updateCategory(id, {
      nameAr: String(value.nameAr).trim(),
      nameEn: value.nameEn?.trim() || null,
      orderIndex: Number(value.orderIndex),
      isActive: Boolean(value.isActive)
    }).pipe(
      finalize(() => {
        this.editSaving = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        if (res.success) {
          this.showToast('تم تعديل التصنيف بنجاح', 'success');
          this.editingId = null;
          this.fetchCategories();
        } else {
          this.showToast(res.message || 'تعذر تعديل التصنيف', 'error');
        }
      },
      error: () => this.showToast('حدث خطأ أثناء تعديل التصنيف', 'error')
    });
  }

  confirmDelete(category: LessonCategoryDto) {
    this.dialogConfig = {
      title: 'حذف التصنيف',
      message: `هل أنت متأكد من حذف تصنيف "${category.nameAr}"؟ لا يمكن التراجع عن هذه العملية.`,
      confirmText: 'حذف',
      type: 'danger',
      action: () => this.deleteCategory(category.id)
    };
  }

  handleDialogClose(confirmed: boolean) {
    const action = this.dialogConfig?.action;
    this.dialogConfig = null;
    if (confirmed && action) action();
  }

  deleteCategory(id: string) {
    this.service.deleteCategory(id).pipe(
      finalize(() => this.cdr.detectChanges())
    ).subscribe({
      next: (res) => {
        if (res.success) {
          this.showToast('تم حذف التصنيف بنجاح', 'success');
          this.fetchCategories();
        } else {
          this.showToast(res.message || 'لا يمكن حذف التصنيف. قد يحتوي على دروس مرتبطة به.', 'error');
        }
      },
      error: () => this.showToast('تعذر حذف التصنيف. قد يحتوي على دروس مرتبطة به.', 'error')
    });
  }

  createFormFieldInvalid(name: string): boolean {
    const control = this.createForm.get(name);
    return Boolean(control && control.invalid && (control.dirty || control.touched));
  }

  editFormFieldInvalid(name: string): boolean {
    const control = this.editForm.get(name);
    return Boolean(control && control.invalid && (control.dirty || control.touched));
  }

  trackById(_index: number, item: LessonCategoryDto): string {
    return item.id;
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
