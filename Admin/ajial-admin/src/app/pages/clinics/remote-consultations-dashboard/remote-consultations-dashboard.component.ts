import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ClinicService } from '../../../services/clinic.service';
import { AdminRemoteConsultationListItem, AdminRemoteConsultationDetail } from '../../../models/clinic.model';

@Component({
  selector: 'app-remote-consultations-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './remote-consultations-dashboard.component.html',
  styleUrl: './remote-consultations-dashboard.component.scss'
})
export class RemoteConsultationsDashboardComponent implements OnInit {
  allConsultations: AdminRemoteConsultationListItem[] = [];
  filteredConsultations: AdminRemoteConsultationListItem[] = [];
  currentFilter = 'all';

  pendingCount = 0;
  approvedCount = 0;
  rejectedCount = 0;

  isLoading = false;
  hasError = false;

  isDetailModalActive = false;
  isLoadingDetail = false;
  selectedConsultation: AdminRemoteConsultationDetail | null = null;

  isRejectModalActive = false;
  rejectionReason = '';
  rejectTargetId = '';

  toastMessage = '';
  toastType = 'success';
  isToastShow = false;

  constructor(private service: ClinicService, private cdr: ChangeDetectorRef) {}

  ngOnInit() { this.fetchConsultations(); }

  fetchConsultations() {
    this.isLoading = true;
    this.hasError = false;
    this.cdr.detectChanges();
    this.service.getConsultations().subscribe({
      next: (res) => {
        this.allConsultations = res.success && res.data?.items ? res.data.items : [];
        this.updateStats();
        this.applyFilter();
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.hasError = true;
        this.allConsultations = [];
        this.filteredConsultations = [];
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  updateStats() {
    this.pendingCount = this.allConsultations.filter(c => c.status === 'pending').length;
    this.approvedCount = this.allConsultations.filter(c => c.status === 'approved').length;
    this.rejectedCount = this.allConsultations.filter(c => c.status === 'rejected').length;
  }

  filterByStatus(status: string) {
    this.currentFilter = status;
    this.applyFilter();
  }

  applyFilter() {
    this.filteredConsultations = this.currentFilter === 'all'
      ? this.allConsultations
      : this.allConsultations.filter(c => c.status === this.currentFilter);
  }

  openDetail(id: string) {
    this.isDetailModalActive = true;
    this.isLoadingDetail = true;
    this.selectedConsultation = null;
    this.cdr.detectChanges();
    this.service.getConsultation(id).subscribe({
      next: (res) => {
        this.selectedConsultation = res.success ? res.data : null;
        this.isLoadingDetail = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.isLoadingDetail = false;
        this.isDetailModalActive = false;
        this.showToast('فشل تحميل تفاصيل الاستشارة', 'error');
        this.cdr.detectChanges();
      }
    });
  }

  closeModal() { this.isDetailModalActive = false; }

  approve(id: string) {
    this.service.approveConsultation(id).subscribe({
      next: (res) => {
        if (res.success) {
          this.showToast('تم قبول الاستشارة بنجاح ✅', 'success');
          this.fetchConsultations();
          this.closeModal();
        } else {
          this.showToast(res.message || 'فشل القبول', 'error');
        }
        this.cdr.detectChanges();
      },
      error: () => {
        this.showToast('فشل الاتصال بالسيرفر', 'error');
        this.cdr.detectChanges();
      }
    });
  }

  openRejectModal(id: string) {
    this.rejectTargetId = id;
    this.rejectionReason = '';
    this.isRejectModalActive = true;
  }

  closeRejectModal() { this.isRejectModalActive = false; }

  confirmReject() {
    const reason = this.rejectionReason.trim();
    if (!reason) {
      this.showToast('الرجاء كتابة سبب الرفض.', 'error');
      return;
    }
    this.service.rejectConsultation(this.rejectTargetId, reason).subscribe({
      next: (res) => {
        if (res.success) {
          this.showToast('تم رفض الاستشارة', 'success');
          this.fetchConsultations();
          this.closeRejectModal();
          this.closeModal();
        } else {
          this.showToast(res.message || 'فشل الرفض', 'error');
        }
        this.cdr.detectChanges();
      },
      error: () => {
        this.showToast('فشل الاتصال بالسيرفر', 'error');
        this.cdr.detectChanges();
      }
    });
  }

  isPending(status: string | null | undefined): boolean {
    return (status ?? '').toLowerCase() === 'pending';
  }

  formatDate(dateStr: string | null | undefined): string {
    if (!dateStr) return '—';
    try {
      return new Date(dateStr).toLocaleDateString('ar-EG', { year: 'numeric', month: 'short', day: 'numeric' });
    } catch { return dateStr; }
  }

  formatPrice(val: number | null | undefined): string {
    if (val == null) return '—';
    return `${val.toLocaleString('ar-EG')} ج.م`;
  }

  formatDuration(minutes: number | null | undefined): string {
    if (minutes == null) return '—';
    return `${minutes} دقيقة`;
  }

  formatWorkingHours(json: string | null | undefined): string {
    if (!json) return '—';
    try {
      const data = JSON.parse(json);
      if (data.type === 'fixed') return `يومياً من ${data.from} إلى ${data.to}`;
      if (data.type === 'specific' && Array.isArray(data.days)) {
        return data.days.map((d: any) => `${d.day}: ${d.from}–${d.to}`).join(' | ');
      }
    } catch { /* fall through */ }
    return json;
  }

  showToast(message: string, type = 'success') {
    this.toastMessage = message;
    this.toastType = type;
    this.isToastShow = true;
    this.cdr.detectChanges();
    setTimeout(() => { this.isToastShow = false; this.cdr.detectChanges(); }, 3500);
  }
}
