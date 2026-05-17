import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { AbstractControl, ReactiveFormsModule, UntypedFormArray, UntypedFormBuilder, UntypedFormGroup, ValidationErrors, Validators } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { finalize } from 'rxjs';
import { DailyQuestionAdminDto, DailyQuestionOptionRequest, UpdateDailyQuestionRequest } from '../../../models/daily-question.model';
import { DailyQuestionsService } from '../../../services/daily-questions.service';
import { LoadingSpinnerComponent } from '../../../shared/components/loading-spinner/loading-spinner.component';

@Component({
  selector: 'app-edit-question',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink, LoadingSpinnerComponent],
  templateUrl: './edit-question.component.html',
  styleUrl: './edit-question.component.scss'
})
export class EditQuestionComponent implements OnInit {
  private fb = inject(UntypedFormBuilder);
  private service = inject(DailyQuestionsService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);

  questionId = '';
  question: DailyQuestionAdminDto | null = null;
  loading = true;
  submitting = false;
  error: string | null = null;

  form = this.fb.group({
    questionText: ['', [Validators.required, Validators.maxLength(500)]],
    starsReward: [1, [Validators.required, Validators.min(1), Validators.pattern(/^[1-9]\d*$/)]],
    isActive: [false],
    options: this.fb.array([], [Validators.minLength(2), this.atLeastOneCorrectValidator])
  });

  get options(): UntypedFormArray {
    return this.form.get('options') as UntypedFormArray;
  }

  ngOnInit() {
    const id = this.route.snapshot.paramMap.get('id');
    if (!id) {
      this.router.navigate(['/daily-questions']);
      return;
    }

    this.questionId = id;
    this.loadQuestion(id);
  }

  loadQuestion(id: string) {
    this.loading = true;
    this.error = null;

    this.service.getById(id).pipe(
      finalize(() => {
        this.loading = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        if (res.success) {
          this.question = res.data;
          this.patchForm(res.data);
        } else {
          this.error = res.message || 'تعذر تحميل السؤال';
        }
      },
      error: (err) => {
        this.error = err.status === 404 ? 'السؤال غير موجود' : 'حدث خطأ أثناء تحميل السؤال';
      }
    });
  }

  createOptionGroup(option?: DailyQuestionOptionRequest): UntypedFormGroup {
    return this.fb.group({
      optionText: [option?.optionText ?? '', [Validators.required, Validators.maxLength(300)]],
      isCorrect: [option?.isCorrect ?? false]
    });
  }

  addOption() {
    this.options.push(this.createOptionGroup());
    this.options.updateValueAndValidity();
  }

  removeOption(index: number) {
    if (this.options.length <= 2) {
      return;
    }

    this.options.removeAt(index);
    this.options.updateValueAndValidity();
  }

  submitForm() {
    this.error = null;

    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.submitting = true;
    this.service.update(this.questionId, this.toRequest()).pipe(
      finalize(() => {
        this.submitting = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        if (res.success) {
          this.router.navigate(['/daily-questions']);
        } else {
          this.error = res.message || 'تعذر تعديل السؤال';
        }
      },
      error: (err) => {
        this.error = this.resolveErrorMessage(err);
      }
    });
  }

  fieldInvalid(name: string): boolean {
    const control = this.form.get(name);
    return Boolean(control && control.invalid && (control.dirty || control.touched));
  }

  optionTextInvalid(index: number): boolean {
    const control = this.options.at(index).get('optionText');
    return Boolean(control && control.invalid && (control.dirty || control.touched));
  }

  correctPercentage(): number {
    if (!this.question || this.question.totalAnswers === 0) {
      return 0;
    }

    return Math.round((this.question.correctAnswers / this.question.totalAnswers) * 100);
  }

  private patchForm(question: DailyQuestionAdminDto) {
    this.form.patchValue({
      questionText: question.questionText,
      starsReward: question.starsReward,
      isActive: question.isActive
    });

    this.options.clear();
    const sortedOptions = [...question.options].sort((a, b) => a.orderIndex - b.orderIndex);
    for (const option of sortedOptions) {
      this.options.push(this.createOptionGroup({
        optionText: option.optionText,
        isCorrect: option.isCorrect
      }));
    }

    while (this.options.length < 2) {
      this.options.push(this.createOptionGroup());
    }

    this.form.markAsPristine();
    this.options.updateValueAndValidity();
  }

  private toRequest(): UpdateDailyQuestionRequest {
    const value = this.form.getRawValue();
    const options = (value.options as DailyQuestionOptionRequest[]).map((option) => ({
      optionText: option.optionText.trim(),
      isCorrect: option.isCorrect
    }));

    return {
      questionText: String(value.questionText).trim(),
      starsReward: Number(value.starsReward),
      isActive: Boolean(value.isActive),
      options
    };
  }

  private atLeastOneCorrectValidator(control: AbstractControl): ValidationErrors | null {
    const options = control.value as DailyQuestionOptionRequest[];
    return options.some((option) => option.isCorrect) ? null : { noCorrectOption: true };
  }

  private resolveErrorMessage(err: { status?: number; error?: { message?: string } }): string {
    if (err.status === 400) {
      return err.error?.message || 'تأكد من صحة بيانات السؤال';
    }

    if (err.status === 404) {
      return 'السؤال غير موجود';
    }

    if (err.status === 401 || err.status === 403) {
      return 'ليست لديك صلاحية لتنفيذ هذه العملية';
    }

    return 'حدث خطأ غير متوقع. حاول مرة أخرى';
  }
}
