import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ConsultationProblemReportService } from '../../../services/consultation-problem-report.service';
import { AdminProblemReportItem } from '../../../models/consultation-problem-report.model';

@Component({
  selector: 'app-specialist-problem-reports',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './problem-reports.component.html',
  styleUrl: './problem-reports.component.scss'
})
export class ProblemReportsComponent implements OnInit {
  reports: AdminProblemReportItem[] = [];
  totalCount = 0;
  newCount = 0;
  isLoading = false;
  hasError = false;

  // فلتر بالحالة: -1 = الكل
  statusFilter = -1;

  // مودال التفاصيل + تحديث الحالة
  isDetailModalActive = false;
  selected: AdminProblemReportItem | null = null;
  editStatus = 0;
  editNote = '';
  isSaving = false;

  // toast
  toastMessage = '';
  toastType: 'success' | 'error' = 'success';
  showToast = false;

  constructor(private service: ConsultationProblemReportService, private cdr: ChangeDetectorRef) {}

  ngOnInit() {
    this.fetch();
  }

  fetch() {
    this.isLoading = true;
    this.hasError = false;
    this.cdr.detectChanges();
    const status = this.statusFilter >= 0 ? this.statusFilter : undefined;
    this.service.getProblemReports(undefined, status).subscribe({
      next: (res) => {
        if (res.success && res.data) {
          this.reports = res.data.items ?? [];
          this.totalCount = res.data.totalCount ?? 0;
          this.newCount = res.data.newCount ?? 0;
        } else {
          this.reports = [];
        }
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.hasError = true;
        this.reports = [];
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  setStatusFilter(status: number) {
    if (this.statusFilter === status) return;
    this.statusFilter = status;
    this.fetch();
  }

  // ── مودال التفاصيل ────────────────────────────────────────────

  openDetail(item: AdminProblemReportItem) {
    this.selected = item;
    this.editStatus = item.statusValue;
    this.editNote = item.adminNote ?? '';
    this.isDetailModalActive = true;
  }

  closeDetail() {
    this.isDetailModalActive = false;
    this.selected = null;
  }

  saveStatus() {
    if (!this.selected || this.isSaving) return;
    this.isSaving = true;
    this.cdr.detectChanges();
    this.service.updateStatus(this.selected.reportId, {
      status: this.editStatus,
      adminNote: this.editNote.trim() || null
    }).subscribe({
      next: (res) => {
        this.isSaving = false;
        if (res.success && res.data) {
          // حدّث العنصر في القائمة
          const idx = this.reports.findIndex(r => r.reportId === res.data.reportId);
          if (idx >= 0) this.reports[idx] = res.data;
          this.selected = res.data;
          this.triggerToast('تم تحديث حالة البلاغ بنجاح', 'success');
          this.fetch();
          this.closeDetail();
        } else {
          this.triggerToast(res.message || 'تعذّر تحديث الحالة', 'error');
        }
        this.cdr.detectChanges();
      },
      error: () => {
        this.isSaving = false;
        this.triggerToast('تعذّر تحديث الحالة، حاول لاحقاً', 'error');
        this.cdr.detectChanges();
      }
    });
  }

  // ── Helpers ──────────────────────────────────────────────────

  /** صنف شارة الحالة: جديد=pending، قيد المراجعة=approved(محايد)، تم الحل=approved. */
  statusClass(statusValue: number): string {
    switch (statusValue) {
      case 0: return 'rejected';   // جديد — يحتاج انتباه
      case 1: return 'pending';    // قيد المراجعة
      case 2: return 'approved';   // تم الحل
      default: return 'pending';
    }
  }

  formatDate(dateStr: string | null | undefined): string {
    if (!dateStr) return '—';
    try {
      return new Date(dateStr).toLocaleDateString('ar-EG', { year: 'numeric', month: 'short', day: 'numeric' });
    } catch { return dateStr; }
  }

  formatDateTime(dateStr: string | null | undefined): string {
    if (!dateStr) return '—';
    try {
      return new Date(dateStr).toLocaleString('ar-EG', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
    } catch { return dateStr; }
  }

  private triggerToast(message: string, type: 'success' | 'error') {
    this.toastMessage = message;
    this.toastType = type;
    this.showToast = true;
    setTimeout(() => { this.showToast = false; this.cdr.detectChanges(); }, 3000);
  }
}
