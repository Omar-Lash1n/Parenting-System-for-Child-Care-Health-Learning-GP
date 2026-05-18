import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, Component, inject } from '@angular/core';
import { AbstractControl, ReactiveFormsModule, UntypedFormArray, UntypedFormBuilder, UntypedFormGroup, ValidationErrors, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { finalize } from 'rxjs';
import {
  CreateLessonRequest,
  CreateLessonQuestionOptionRequest,
  LessonCategoryDto
} from '../../../models/lesson.model';
import { LessonsService } from '../../../services/lessons.service';
import { LessonAiGenerationService } from '../../../services/lesson-ai-generation.service';
import { LoadingSpinnerComponent } from '../../../shared/components/loading-spinner/loading-spinner.component';

@Component({
  selector: 'app-create-lesson',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterLink, LoadingSpinnerComponent],
  templateUrl: './create-lesson.component.html',
  styleUrl: './create-lesson.component.scss'
})
export class CreateLessonComponent {
  private fb = inject(UntypedFormBuilder);
  private service = inject(LessonsService);
  private aiService = inject(LessonAiGenerationService);
  private router = inject(Router);
  private cdr = inject(ChangeDetectorRef);

  categories: LessonCategoryDto[] = [];
  submitting = false;
  error: string | null = null;
  aiGenerating = false;
  aiError: string | null = null;

  form = this.fb.group({
    categoryId: ['', [Validators.required]],
    titleAr: ['', [Validators.required, Validators.maxLength(200)]],
    contentAr: ['', [Validators.required, Validators.maxLength(10000)]],
    imageUrl: [''],
    videoUrl: [''],
    isActive: [false],
    questions: this.fb.array([], [this.atLeastOneQuestionValidator])
  });

  constructor() {
    this.service.getCategories().subscribe({
      next: (res) => {
        if (res.success) this.categories = res.data ?? [];
        this.cdr.detectChanges();
      },
      error: () => {}
    });
  }

  get questions(): UntypedFormArray {
    return this.form.get('questions') as UntypedFormArray;
  }

  getOptions(qIndex: number): UntypedFormArray {
    return this.questions.at(qIndex).get('options') as UntypedFormArray;
  }

  createOptionGroup(option?: CreateLessonQuestionOptionRequest): UntypedFormGroup {
    return this.fb.group({
      optionText: [option?.optionText ?? '', [Validators.required, Validators.maxLength(300)]],
      isCorrect: [option?.isCorrect ?? false]
    });
  }

  createQuestionGroup(): UntypedFormGroup {
    return this.fb.group({
      questionText: ['', [Validators.required, Validators.maxLength(500)]],
      starsReward: [1, [Validators.required, Validators.min(1)]],
      options: this.fb.array([
        this.createOptionGroup(),
        this.createOptionGroup()
      ], [this.exactlyOneCorrectValidator])
    });
  }

  addQuestion() {
    this.questions.push(this.createQuestionGroup());
    this.questions.updateValueAndValidity();
  }

  removeQuestion(qIndex: number) {
    this.questions.removeAt(qIndex);
    this.questions.updateValueAndValidity();
  }

  addOption(qIndex: number) {
    this.getOptions(qIndex).push(this.createOptionGroup());
    this.getOptions(qIndex).updateValueAndValidity();
  }

  removeOption(qIndex: number, oIndex: number) {
    const options = this.getOptions(qIndex);
    if (options.length <= 2) return;
    options.removeAt(oIndex);
    options.updateValueAndValidity();
  }

  onOptionCorrectChange(qIndex: number, oIndex: number, event: Event): void {
    const checked = (event.target as HTMLInputElement).checked;
    if (checked) {
      const options = this.getOptions(qIndex);
      for (let i = 0; i < options.length; i++) {
        if (i !== oIndex) {
          options.at(i).get('isCorrect')?.setValue(false, { emitEvent: false });
        }
      }
      options.updateValueAndValidity();
    }
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
        this.form.patchValue({
          titleAr: result.titleAr,
          contentAr: result.contentAr
        });

        while (this.questions.length) {
          this.questions.removeAt(0);
        }

        result.questions.forEach((q) => {
          const qGroup = this.fb.group({
            questionText: [q.questionText, [Validators.required, Validators.maxLength(500)]],
            starsReward: [q.starsReward, [Validators.required, Validators.min(1)]],
            options: this.fb.array([], [this.exactlyOneCorrectValidator])
          });
          const optionsArr = qGroup.get('options') as UntypedFormArray;
          q.options.forEach((o) => optionsArr.push(this.createOptionGroup(o)));
          this.questions.push(qGroup);
        });

        this.questions.updateValueAndValidity();
        this.cdr.detectChanges();
      },
      error: (err: Error) => {
        this.aiError = err.message || 'حدث خطأ أثناء التوليد. حاول مرة أخرى.';
      }
    });
  }

  submitForm() {
    this.error = null;

    if (this.questions.length === 0) {
      this.error = 'يجب إضافة سؤال واحد على الأقل';
      this.form.markAllAsTouched();
      return;
    }

    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.submitting = true;
    this.service.createLesson(this.toRequest()).pipe(
      finalize(() => {
        this.submitting = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        if (res.success) {
          this.router.navigate(['/lessons']);
        } else {
          this.error = res.message || 'تعذر إنشاء الدرس';
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

  questionFieldInvalid(qIndex: number, fieldName: string): boolean {
    const control = this.questions.at(qIndex).get(fieldName);
    return Boolean(control && control.invalid && (control.dirty || control.touched));
  }

  optionFieldInvalid(qIndex: number, oIndex: number): boolean {
    const control = this.getOptions(qIndex).at(oIndex).get('optionText');
    return Boolean(control && control.invalid && (control.dirty || control.touched));
  }

  private toRequest(): CreateLessonRequest {
    const value = this.form.getRawValue();
    return {
      categoryId: value.categoryId,
      titleAr: String(value.titleAr).trim(),
      contentAr: String(value.contentAr).trim(),
      imageUrl: value.imageUrl?.trim() || null,
      videoUrl: value.videoUrl?.trim() || null,
      isActive: Boolean(value.isActive),
      questions: (value.questions as { questionText: string; starsReward: number; options: CreateLessonQuestionOptionRequest[] }[]).map((q) => ({
        questionText: q.questionText.trim(),
        starsReward: Number(q.starsReward),
        options: q.options.map((o) => ({
          optionText: o.optionText.trim(),
          isCorrect: Boolean(o.isCorrect)
        }))
      }))
    };
  }

  private atLeastOneQuestionValidator(control: AbstractControl): ValidationErrors | null {
    const arr = control.value as unknown[];
    return arr.length >= 1 ? null : { required: true };
  }

  private exactlyOneCorrectValidator(control: AbstractControl): ValidationErrors | null {
    const options = control.value as { isCorrect: boolean }[];
    const correctCount = options.filter((o) => o.isCorrect).length;
    return correctCount === 1 ? null : { notExactlyOneCorrect: true };
  }

  private resolveErrorMessage(err: { status?: number; error?: { message?: string } }): string {
    if (err.status === 400) return err.error?.message || 'تأكد من صحة بيانات الدرس';
    if (err.status === 401 || err.status === 403) return 'ليست لديك صلاحية لتنفيذ هذه العملية';
    return 'حدث خطأ غير متوقع. حاول مرة أخرى';
  }
}
