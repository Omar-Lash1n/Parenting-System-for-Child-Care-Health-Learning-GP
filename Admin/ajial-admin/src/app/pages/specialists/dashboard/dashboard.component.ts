import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { HttpClientModule, HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule, HttpClientModule],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  API_BASE = 'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';
  
  allSpecialists: any[] = [];
  filteredSpecialists: any[] = [];
  currentFilter: string = 'all';
  
  pendingCount = 0;
  approvedCount = 0;
  rejectedCount = 0;

  isLoading = false;
  hasError = false;

  // Modals state
  isDetailModalActive = false;
  isRejectModalActive = false;
  
  selectedSpecialist: any = null;
  rejectionReason = '';

  toastMessage = '';
  toastType = 'success';
  isToastShow = false;

  constructor(private http: HttpClient, private cdr: ChangeDetectorRef) {}

  ngOnInit() {
    this.fetchSpecialists();
  }

  fetchSpecialists() {
    this.isLoading = true;
    this.hasError = false;
    this.cdr.detectChanges();
    this.http.get<any>(`${this.API_BASE}/Specialist`).subscribe({
      next: (res) => {
        if (res.success && Array.isArray(res.data)) {
          this.allSpecialists = res.data;
        } else {
          this.allSpecialists = [];
        }
        this.updateStats();
        this.applyFilter();
        this.isLoading = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Fetch error:', err);
        this.hasError = true;
        this.allSpecialists = [];
        this.filteredSpecialists = [];
        this.isLoading = false;
        this.cdr.detectChanges();
      }
    });
  }

  updateStats() {
    this.pendingCount = this.allSpecialists.filter((s) => s.status === 'Pending').length;
    this.approvedCount = this.allSpecialists.filter((s) => s.status === 'Approved').length;
    this.rejectedCount = this.allSpecialists.filter((s) => s.status === 'Rejected').length;
  }

  filterByStatus(status: string) {
    this.currentFilter = status;
    this.applyFilter();
  }

  applyFilter() {
    this.filteredSpecialists = this.currentFilter === 'all'
      ? this.allSpecialists
      : this.allSpecialists.filter((s) => s.status === this.currentFilter);
  }

  formatDate(dateStr: string) {
    if (!dateStr) return '—';
    try {
      const d = new Date(dateStr);
      return d.toLocaleDateString('ar-EG', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
      });
    } catch {
      return dateStr;
    }
  }

  getStatusData(status: string) {
    const map: Record<string, { label: string, cls: string }> = {
      Pending: { label: 'قيد المراجعة', cls: 'pending' },
      Approved: { label: 'مقبول', cls: 'approved' },
      Rejected: { label: 'مرفوض', cls: 'rejected' },
    };
    return map[status] || { label: status, cls: 'pending' };
  }

  openDetail(s: any) {
    this.selectedSpecialist = s;
    this.isDetailModalActive = true;
  }

  closeModal() {
    this.isDetailModalActive = false;
  }

  approveSpecialist(id: string) {
    this.updateStatus(id, 2, null);
    this.closeModal();
  }

  openRejectModal(id: string) {
    if (!this.selectedSpecialist || this.selectedSpecialist.specialistId !== id) {
      this.selectedSpecialist = this.allSpecialists.find(s => s.specialistId === id);
    }
    this.rejectionReason = '';
    this.isRejectModalActive = true;
  }

  closeRejectModal() {
    this.isRejectModalActive = false;
  }

  confirmReject() {
    const reason = this.rejectionReason.trim();
    if (!reason) {
      this.showToast('الرجاء كتابة سبب الرفض.', 'error');
      return;
    }
    this.updateStatus(this.selectedSpecialist.specialistId, 3, reason);
    this.closeRejectModal();
    this.closeModal();
  }

  updateStatus(specialistId: string, status: number, rejectionReason: string | null) {
    const body: any = { specialistId, status };
    if (rejectionReason) {
      body.rejectionReason = rejectionReason;
    }

    this.http.post<any>(`${this.API_BASE}/Specialist/update-status`, body).subscribe({
      next: (res) => {
        this.showToast(status === 2 ? 'تم قبول المتخصص بنجاح ✅' : 'تم رفض المتخصص بنجاح ❌', 'success');
        this.fetchSpecialists();
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Update status error:', err);
        this.showToast('فشل الاتصال بالسيرفر أو فشل التحديث.', 'error');
        this.cdr.detectChanges();
      }
    });
  }

  showToast(message: string, type: string = 'success') {
    this.toastMessage = message;
    this.toastType = type;
    this.isToastShow = true;
    this.cdr.detectChanges();

    setTimeout(() => {
      this.isToastShow = false;
      this.cdr.detectChanges();
    }, 3500);
  }

  onImageError(event: any) {
    event.target.outerHTML = "<div class='table-avatar-placeholder'>👤</div>";
  }

  openDoc(url: string | null) {
    if (url) window.open(url, '_blank');
  }
}
