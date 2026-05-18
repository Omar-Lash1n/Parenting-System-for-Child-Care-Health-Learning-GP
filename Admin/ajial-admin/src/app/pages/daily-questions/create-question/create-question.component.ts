import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { AbstractControl, ReactiveFormsModule, UntypedFormArray, UntypedFormBuilder, UntypedFormGroup, ValidationErrors, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { finalize } from 'rxjs';
import { CreateDailyQuestionRequest, DailyQuestionOptionRequest } from '../../../models/daily-question.model';
import { DailyQuestionsService } from '../../../services/daily-questions.service';
import { AiGenerationService } from '../../../services/ai-generation.service';
import { LoadingSpinnerComponent } from '../../../shared/components/loading-spinner/loading-spinner.component';

@Component({
  selector: 'app-create-question',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink, LoadingSpinnerComponent],
  templateUrl: './create-question.component.html',
  styleUrl: './create-question.component.scss'
})
export class CreateQuestionComponent {
  private fb = inject(UntypedFormBuilder);
  private service = inject(DailyQuestionsService);
  private aiService = inject(AiGenerationService);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);

  submitting = false;
  error: string | null = null;
  aiGenerating = false;
  aiError: string | null = null;

  form = this.fb.group({
    questionText: ['', [Validators.required, Validators.maxLength(500)]],
    starsReward: [1, [Validators.required, Validators.min(1), Validators.pattern(/^[1-9]\d*$/)]],
    isActive: [false],
    options: this.fb.array([
      this.createOptionGroup(),
      this.createOptionGroup()
    ], [Validators.minLength(2), this.atLeastOneCorrectValidator])
  });

  get options(): UntypedFormArray {
    return this.form.get('options') as UntypedFormArray;
  }

  createOptionGroup(option?: DailyQuestionOptionRequest): UntypedFormGroup {
    return this.fb.group({
      optionText: [option?.optionText ?? '', [Validators.required, Validators.maxLength(300)]],
      isCorrect: [option?.isCorrect ?? false]
    });
  }

  generateWithAi(): void {
    this.aiError = null;
    this.aiGenerating = true;

    this.aiService.generate().pipe(
      finalize(() => {
        this.aiGenerating = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (result) => {
        while (this.options.length) {
          this.options.removeAt(0);
        }
        result.options.forEach((o) => this.options.push(this.createOptionGroup(o)));
        this.options.updateValueAndValidity();
        this.form.patchValue({ questionText: result.questionText, starsReward: result.starsReward });
        this.cdr.detectChanges();
      },
      error: (err: Error) => {
        this.aiError = err.message || 'حدث خطأ أثناء التوليد. حاول مرة أخرى.';
      }
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
    this.service.create(this.toRequest()).pipe(
      finalize(() => {
        this.submitting = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        if (res.success) {
          this.router.navigate(['/daily-questions']);
        } else {
          this.error = res.message || 'تعذر إنشاء السؤال';
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

  private toRequest(): CreateDailyQuestionRequest {
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

    if (err.status === 401 || err.status === 403) {
      return 'ليست لديك صلاحية لتنفيذ هذه العملية';
    }

    return 'حدث خطأ غير متوقع. حاول مرة أخرى';
  }
}
