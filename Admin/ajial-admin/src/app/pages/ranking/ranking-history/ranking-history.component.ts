import { ChangeDetectorRef, Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { finalize } from 'rxjs';
import { RankingService } from '../../../services/ranking.service';
import { AdminPublishedRanking } from '../../../models/ranking.model';
import { LoadingSpinnerComponent } from '../../../shared/components/loading-spinner/loading-spinner.component';

@Component({
  selector: 'app-ranking-history',
  standalone: true,
  imports: [CommonModule, RouterLink, LoadingSpinnerComponent],
  templateUrl: './ranking-history.component.html',
  styleUrl: './ranking-history.component.scss'
})
export class RankingHistoryComponent implements OnInit {
  private service = inject(RankingService);
  private cdr = inject(ChangeDetectorRef);

  cycles: AdminPublishedRanking[] = [];
  loading = false;
  error: string | null = null;

  ngOnInit() {
    this.loadHistory();
  }

  loadHistory() {
    this.loading = true;
    this.error = null;
    this.service.getRankingHistory().pipe(
      finalize(() => {
        this.loading = false;
        this.cdr.detectChanges();
      })
    ).subscribe({
      next: (res) => {
        if (res.success) {
          this.cycles = res.data ?? [];
        } else {
          this.error = res.message || 'تعذر تحميل سجل المواسم';
        }
      },
      error: () => {
        this.error = 'حدث خطأ أثناء تحميل سجل المواسم';
      }
    });
  }

  badgeLabel(badge: string | null): string {
    switch (badge) {
      case 'Gold': return 'ذهبي';
      case 'Silver': return 'فضي';
      case 'Bronze': return 'برونزي';
      default: return '';
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

  rankMedal(rank: number): string {
    if (rank === 1) return '🥇';
    if (rank === 2) return '🥈';
    if (rank === 3) return '🥉';
    return `#${rank}`;
  }

  trackByCycleId(_i: number, c: AdminPublishedRanking) {
    return c.cycleId;
  }
}
