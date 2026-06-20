import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ConsultationRatingService } from '../../../services/consultation-rating.service';
import {
  AdminRatingItem,
  AdminDoctorRating
} from '../../../models/consultation-rating.model';

@Component({
  selector: 'app-specialist-ratings',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './ratings.component.html',
  styleUrl: './ratings.component.scss'
})
export class RatingsComponent implements OnInit {
  // عرض حالي: ملخص الأطباء أو كل التقييمات
  view: 'doctors' | 'all' = 'doctors';

  // ملخص الأطباء
  doctors: AdminDoctorRating[] = [];
  doctorCount = 0;
  overallAverageRating = 0;
  totalRatings = 0;
  isLoadingDoctors = false;
  hasDoctorsError = false;

  // كل التقييمات
  ratings: AdminRatingItem[] = [];
  listAverage = 0;
  isLoadingRatings = false;
  hasRatingsError = false;

  // فلاتر قائمة التقييمات
  issueFilter: 'all' | 'issues' = 'all';
  specialistFilterId = '';
  specialistFilterName = '';

  // مودال تفاصيل تقييم
  isDetailModalActive = false;
  selectedRating: AdminRatingItem | null = null;

  constructor(private service: ConsultationRatingService, private cdr: ChangeDetectorRef) {}

  ngOnInit() {
    this.fetchDoctors();
    this.fetchRatings();
  }

  // ── ملخص الأطباء ──────────────────────────────────────────────

  fetchDoctors() {
    this.isLoadingDoctors = true;
    this.hasDoctorsError = false;
    this.cdr.detectChanges();
    this.service.getDoctorRatingsSummary().subscribe({
      next: (res) => {
        if (res.success && res.data) {
          this.doctors = res.data.doctors ?? [];
          this.doctorCount = res.data.doctorCount ?? 0;
          this.overallAverageRating = res.data.overallAverageRating ?? 0;
          this.totalRatings = res.data.totalRatings ?? 0;
        } else {
          this.doctors = [];
        }
        this.isLoadingDoctors = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.hasDoctorsError = true;
        this.doctors = [];
        this.isLoadingDoctors = false;
        this.cdr.detectChanges();
      }
    });
  }

  // ── كل التقييمات ──────────────────────────────────────────────

  fetchRatings() {
    this.isLoadingRatings = true;
    this.hasRatingsError = false;
    this.cdr.detectChanges();
    const hadIssue = this.issueFilter === 'issues' ? true : undefined;
    const specialistId = this.specialistFilterId || undefined;
    this.service.getRatings(specialistId, hadIssue).subscribe({
      next: (res) => {
        if (res.success && res.data) {
          this.ratings = res.data.items ?? [];
          this.listAverage = res.data.averageRating ?? 0;
        } else {
          this.ratings = [];
        }
        this.isLoadingRatings = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.hasRatingsError = true;
        this.ratings = [];
        this.isLoadingRatings = false;
        this.cdr.detectChanges();
      }
    });
  }

  setIssueFilter(filter: 'all' | 'issues') {
    if (this.issueFilter === filter) return;
    this.issueFilter = filter;
    this.fetchRatings();
  }

  viewDoctorRatings(doctor: AdminDoctorRating) {
    this.specialistFilterId = doctor.specialistId;
    this.specialistFilterName = doctor.doctorName;
    this.issueFilter = 'all';
    this.view = 'all';
    this.fetchRatings();
  }

  clearSpecialistFilter() {
    this.specialistFilterId = '';
    this.specialistFilterName = '';
    this.fetchRatings();
  }

  switchView(v: 'doctors' | 'all') {
    this.view = v;
  }

  // ── مودال التفاصيل ────────────────────────────────────────────

  openDetail(item: AdminRatingItem) {
    this.selectedRating = item;
    this.isDetailModalActive = true;
  }

  closeDetail() {
    this.isDetailModalActive = false;
    this.selectedRating = null;
  }

  // ── Helpers ──────────────────────────────────────────────────

  /** يُرجع مصفوفة 5 قيم منطقية لرسم النجوم (مملوءة حتى التقييم). */
  starArray(rating: number): boolean[] {
    return [1, 2, 3, 4, 5].map(i => i <= rating);
  }

  formatDate(dateStr: string | null | undefined): string {
    if (!dateStr) return '—';
    try {
      return new Date(dateStr).toLocaleDateString('ar-EG', { year: 'numeric', month: 'short', day: 'numeric' });
    } catch { return dateStr; }
  }

  avg(val: number | null | undefined): string {
    if (val == null) return '0.0';
    return val.toFixed(1);
  }
}
