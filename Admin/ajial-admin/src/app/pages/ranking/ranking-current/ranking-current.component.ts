import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { AbstractControl, FormBuilder, ReactiveFormsModule, ValidationErrors, Validators } from '@angular/forms';
import { finalize } from 'rxjs';
import { RankingService } from '../../../services/ranking.service';
import { PagedAdminCurrentRanking, AdminCurrentRankingEntry } from '../../../models/ranking.model';
import { LoadingSpinnerComponent } from '../../../shared/components/loading-spinner/loading-spinner.component';

function futureDateValidator(control: AbstractControl): ValidationErrors | null {
  if (!control.value) return null;
  return new Date(control.value) > new Date() ? null : { pastDate: true };
}

@Component({
  selector: 'app-ranking-current',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, LoadingSpinnerComponent],
  templateUrl: './ranking-current.component.html',
  styleUrl: './ranking-current.component.scss'
})
export class RankingCurrentComponent implements OnInit {
  private service = inject(RankingService);
  private cdr = inject(ChangeDetectorRef);
  private router = inject(Router);
  private fb = inject(FormBuilder);
  private toastTimer: ReturnType<typeof setTimeout> | null = null;

  ranking: PagedAdminCurrentRanking | null = null;
  loading = false;
  error: string | null = null;
  showPublishModal = false;
  publishing = false;
  toast: { message: string; type: 'success' | 'error' | 'warning' } | null = null;

  currentPage = 1;
  readonly pageSize = 20;

  publishForm = this.fb.group({
    seasonName: ['', [Validators.required, Validators.maxLength(100)]],
    nextPublishAt: ['', [Validators.required, futureDateValidator]]
  });

  get minDateTime(): string {
    const d = new Date();
    d.setMinutes(d.getMinutes() + 1);
    return d.toISOString().slice(0, 16);
  }

  ngOnInit() {
    this.loadRanking(1);
  }

  loadRanking(page: number) {
    this.loading = true;
    this.error = null;
    this.service.getCurrentRanking(page, this.pageSize).pipe(
      finalize(() => {
        this.loading = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        if (res.success) {
          this.ranking = res.data;
          this.currentPage = res.data.page;
        } else {
          this.error = res.message || 'تعذر تحميل بيانات الترتيب';
        }
      },
      error: () => {
        this.error = 'حدث خطأ أثناء تحميل بيانات الترتيب';
      }
    });
  }

  prevPage() {
    if (this.currentPage > 1) this.loadRanking(this.currentPage - 1);
  }

  nextPage() {
    if (this.ranking?.hasNextPage) this.loadRanking(this.currentPage + 1);
  }

  openPublishModal() {
    this.publishForm.reset();
    this.showPublishModal = true;
  }

  closePublishModal() {
    this.showPublishModal = false;
  }

  submitPublish() {
    if (this.publishForm.invalid) {
      this.publishForm.markAllAsTouched();
      return;
    }

    const { seasonName, nextPublishAt } = this.publishForm.value;
    this.publishing = true;

    this.service.publishRanking({
      seasonName: seasonName!,
      nextPublishAt: new Date(nextPublishAt!).toISOString()
    }).pipe(
      finalize(() => {
        this.publishing = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        if (res.success) {
          this.showPublishModal = false;
          this.showToast('تم نشر الترتيب بنجاح', 'success');
          this.loadRanking(1);
        } else {
          this.showToast(res.message || 'تعذر نشر الترتيب', 'error');
        }
      },
      error: () => this.showToast('حدث خطأ أثناء نشر الترتيب', 'error')
    });
  }

  goToHistory() {
    this.router.navigate(['/ranking/history']);
  }

  badgeLabel(badge: string | null): string {
    switch (badge) {
      case 'Gold': return 'ذهبي';
      case 'Silver': return 'فضي';
      case 'Bronze': return 'برونزي';
      default: return '—';
    }
  }

  badgeClass(badge: string | null): string {
    switch (badge) {
      case 'Gold': return 'badge-gold';
      case 'Silver': return 'badge-silver';
      case 'Bronze': return 'badge-bronze';
      default: return '';
    }
  }

  trackByRank(_i: number, e: AdminCurrentRankingEntry) {
    return e.rank;
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
