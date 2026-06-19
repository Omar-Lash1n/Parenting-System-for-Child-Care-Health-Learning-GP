import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ConsultationPaymentService } from '../../../services/consultation-payment.service';

@Component({
  selector: 'app-payment-settings',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './payment-settings.component.html',
  styleUrl: './payment-settings.component.scss'
})
export class PaymentSettingsComponent implements OnInit {
  vodafoneCashNumber = '';
  instaPayNumber = '';

  isLoading = false;
  isSaving = false;
  hasError = false;

  toastMessage = '';
  toastType = 'success';
  isToastShow = false;

  constructor(private service: ConsultationPaymentService, private cdr: ChangeDetectorRef) {}

  ngOnInit() { this.fetchSettings(); }

  fetchSettings() {
    this.isLoading = true;
    this.hasError = false;
    this.cdr.detectChanges();
    this.service.getPaymentSettings().subscribe({
      next: (res) => {
        if (res.success && res.data) {
          this.vodafoneCashNumber = res.data.vodafoneCashNumber || '';
          this.instaPayNumber = res.data.instaPayNumber || '';
        }
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.hasError = true;
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  save() {
    const vod = this.vodafoneCashNumber.trim();
    const inst = this.instaPayNumber.trim();

    if (!vod && !inst) {
      this.showToast('الرجاء إدخال رقم واحد على الأقل.', 'error');
      return;
    }

    this.isSaving = true;
    this.cdr.detectChanges();
    this.service.updatePaymentSettings({
      vodafoneCashNumber: vod || undefined,
      instaPayNumber: inst || undefined
    }).subscribe({
      next: (res) => {
        if (res.success) {
          if (res.data) {
            this.vodafoneCashNumber = res.data.vodafoneCashNumber || '';
            this.instaPayNumber = res.data.instaPayNumber || '';
          }
          this.showToast('تم تحديث إعدادات الدفع بنجاح ✅', 'success');
        } else {
          this.showToast(res.message || 'فشل التحديث', 'error');
        }
        this.isSaving = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.showToast('فشل الاتصال بالسيرفر', 'error');
        this.isSaving = false;
        this.cdr.detectChanges();
      }
    });
  }

  showToast(message: string, type = 'success') {
    this.toastMessage = message;
    this.toastType = type;
    this.isToastShow = true;
    this.cdr.detectChanges();
    setTimeout(() => { this.isToastShow = false; this.cdr.detectChanges(); }, 3500);
  }
}
