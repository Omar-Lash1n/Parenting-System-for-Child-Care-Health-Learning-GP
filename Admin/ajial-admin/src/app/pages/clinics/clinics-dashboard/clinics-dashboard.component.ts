import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ClinicService } from '../../../services/clinic.service';
import { AdminClinicListItem, AdminClinicDetail } from '../../../models/clinic.model';

@Component({
  selector: 'app-clinics-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './clinics-dashboard.component.html',
  styleUrl: './clinics-dashboard.component.scss'
})
export class ClinicsDashboardComponent implements OnInit {
  allClinics: AdminClinicListItem[] = [];
  filteredClinics: AdminClinicListItem[] = [];
  currentFilter = 'all';

  pendingCount = 0;
  approvedCount = 0;
  rejectedCount = 0;

  isLoading = false;
  hasError = false;

  isDetailModalActive = false;
  isLoadingDetail = false;
  selectedClinic: AdminClinicDetail | null = null;

  isRejectModalActive = false;
  rejectionReason = '';
  rejectTargetId = '';

  toastMessage = '';
  toastType = 'success';
  isToastShow = false;

  constructor(private service: ClinicService, private cdr: ChangeDetectorRef) {}

  ngOnInit() { this.fetchClinics(); }

  fetchClinics() {
    this.isLoading = true;
    this.hasError = false;
    this.cdr.detectChanges();
    this.service.getClinics().subscribe({
      next: (res) => {
        this.allClinics = res.success && res.data?.items ? res.data.items : [];
        this.updateStats();
        this.applyFilter();
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.hasError = true;
        this.allClinics = [];
        this.filteredClinics = [];
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  updateStats() {
    this.pendingCount = this.allClinics.filter(c => c.status === 'pending').length;
    this.approvedCount = this.allClinics.filter(c => c.status === 'approved').length;
    this.rejectedCount = this.allClinics.filter(c => c.status === 'rejected').length;
  }

  filterByStatus(status: string) {
    this.currentFilter = status;
    this.applyFilter();
  }

  applyFilter() {
    this.filteredClinics = this.currentFilter === 'all'
      ? this.allClinics
      : this.allClinics.filter(c => c.status === this.currentFilter);
  }

  openDetail(id: string) {
    this.isDetailModalActive = true;
    this.isLoadingDetail = true;
    this.selectedClinic = null;
    this.cdr.detectChanges();
    this.service.getClinic(id).subscribe({
      next: (res) => {
        this.selectedClinic = res.success ? res.data : null;
        this.isLoadingDetail = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.isLoadingDetail = false;
        this.isDetailModalActive = false;
        this.showToast('فشل تحميل تفاصيل العيادة', 'error');
        this.cdr.detectChanges();
      }
    });
  }

  closeModal() { this.isDetailModalActive = false; }

  approve(id: string) {
    this.service.approveClinic(id).subscribe({
      next: (res) => {
        if (res.success) {
          this.showToast('تم قبول العيادة بنجاح ✅', 'success');
          this.fetchClinics();
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
    this.service.rejectClinic(this.rejectTargetId, reason).subscribe({
      next: (res) => {
        if (res.success) {
          this.showToast('تم رفض العيادة', 'success');
          this.fetchClinics();
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

  openDoc(url: string | null) {
    if (url) window.open(url, '_blank');
  }

  showToast(message: string, type = 'success') {
    this.toastMessage = message;
    this.toastType = type;
    this.isToastShow = true;
    this.cdr.detectChanges();
    setTimeout(() => { this.isToastShow = false; this.cdr.detectChanges(); }, 3500);
  }
}
