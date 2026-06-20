import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ConsultationPaymentService } from '../../../services/consultation-payment.service';
import { AdminCancellationItem } from '../../../models/consultation-payment.model';

@Component({
  selector: 'app-cancellations-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './cancellations-dashboard.component.html',
  styleUrl: './cancellations-dashboard.component.scss'
})
export class CancellationsDashboardComponent implements OnInit {
  allCancellations: AdminCancellationItem[] = [];

  totalCount = 0;
  pendingRefundCount = 0;
  totalRefundDue = 0;

  isLoading = false;
  hasError = false;

  isDetailModalActive = false;
  selected: AdminCancellationItem | null = null;

  isImageModalActive = false;
  imageModalUrl = '';

  constructor(private service: ConsultationPaymentService, private cdr: ChangeDetectorRef) {}

  ngOnInit() { this.fetch(); }

  fetch() {
    this.isLoading = true;
    this.hasError = false;
    this.cdr.detectChanges();
    this.service.getCancellations().subscribe({
      next: (res) => {
        this.allCancellations = res.success && res.data?.items ? res.data.items : [];
        this.updateStats();
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.hasError = true;
        this.allCancellations = [];
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  updateStats() {
    this.totalCount = this.allCancellations.length;
    this.pendingRefundCount = this.allCancellations.filter(c => (c.refundAmount || 0) > 0).length;
    this.totalRefundDue = this.allCancellations.reduce((sum, c) => sum + (c.refundAmount || 0), 0);
  }

  openDetail(item: AdminCancellationItem) {
    this.selected = item;
    this.isDetailModalActive = true;
  }

  closeModal() { this.isDetailModalActive = false; }

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
}
