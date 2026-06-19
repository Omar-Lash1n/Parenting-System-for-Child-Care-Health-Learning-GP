import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ConsultationPaymentService } from '../../../services/consultation-payment.service';
import { AdminPaymentListItem, AdminPaymentDetail } from '../../../models/consultation-payment.model';

@Component({
  selector: 'app-payments-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './payments-dashboard.component.html',
  styleUrl: './payments-dashboard.component.scss'
})
export class PaymentsDashboardComponent implements OnInit {
  allPayments: AdminPaymentListItem[] = [];
  filteredPayments: AdminPaymentListItem[] = [];
  currentFilter = 'all';

  pendingCount = 0;
  approvedCount = 0;
  rejectedCount = 0;

  isLoading = false;
  hasError = false;

  isDetailModalActive = false;
  isLoadingDetail = false;
  selectedPayment: AdminPaymentDetail | null = null;

  isRejectModalActive = false;
  rejectionReason = '';
  rejectTargetId = '';

  isImageModalActive = false;
  imageModalUrl = '';

  toastMessage = '';
  toastType = 'success';
  isToastShow = false;

  constructor(private service: ConsultationPaymentService, private cdr: ChangeDetectorRef) {}

  ngOnInit() { this.fetchPayments(); }

  fetchPayments() {
    this.isLoading = true;
    this.hasError = false;
    this.cdr.detectChanges();
    this.service.getPayments().subscribe({
      next: (res) => {
        this.allPayments = res.success && res.data?.items ? res.data.items : [];
        this.updateStats();
        this.applyFilter();
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.hasError = true;
        this.allPayments = [];
        this.filteredPayments = [];
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  updateStats() {
    this.pendingCount = this.allPayments.filter(p => p.status?.toLowerCase() === 'pending').length;
    this.approvedCount = this.allPayments.filter(p => p.status?.toLowerCase() === 'approved').length;
    this.rejectedCount = this.allPayments.filter(p => p.status?.toLowerCase() === 'rejected').length;
  }

  filterByStatus(status: string) {
    this.currentFilter = status;
    this.applyFilter();
  }

  applyFilter() {
    this.filteredPayments = this.currentFilter === 'all'
      ? this.allPayments
      : this.allPayments.filter(p => p.status?.toLowerCase() === this.currentFilter);
  }

  openDetail(id: string) {
    this.isDetailModalActive = true;
    this.isLoadingDetail = true;
    this.selectedPayment = null;
    this.cdr.detectChanges();
    this.service.getPayment(id).subscribe({
      next: (res) => {
        this.selectedPayment = res.success ? res.data : null;
        this.isLoadingDetail = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.isLoadingDetail = false;
        this.isDetailModalActive = false;
        this.showToast('فشل تحميل تفاصيل الدفع', 'error');
        this.cdr.detectChanges();
      }
    });
  }

  closeModal() { this.isDetailModalActive = false; }

  approve(id: string) {
    this.service.approvePayment(id).subscribe({
      next: (res) => {
        if (res.success) {
          this.showToast('تم قبول الدفع وتأكيد الحجز ✅', 'success');
          this.fetchPayments();
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
    this.service.rejectPayment(this.rejectTargetId, reason).subscribe({
      next: (res) => {
        if (res.success) {
          this.showToast('تم رفض الدفع', 'success');
          this.fetchPayments();
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

  openReceiptImage(url: string | null) {
    if (url) {
      this.imageModalUrl = url;
      this.isImageModalActive = true;
    }
  }

  closeImageModal() { this.isImageModalActive = false; }

  openImageInNewTab(url: string | null) {
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
