import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ConsultationApiResponse } from '../models/consultation-payment.model';
import {
  AdminRatingListResponse,
  AdminDoctorRatingSummaryResponse
} from '../models/consultation-rating.model';

@Injectable({ providedIn: 'root' })
export class ConsultationRatingService {
  private http = inject(HttpClient);
  private base = 'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api/admin/consultations';

  /** GET /ratings — قائمة استبيانات تقييم الجلسات (فلتر اختياري بالطبيب / من أبلغ عن مشكلة). */
  getRatings(specialistId?: string, hadIssue?: boolean, page = 1, pageSize = 100): Observable<ConsultationApiResponse<AdminRatingListResponse>> {
    let params = new HttpParams().set('page', page).set('pageSize', pageSize);
    if (specialistId) {
      params = params.set('specialistId', specialistId);
    }
    if (hadIssue !== undefined && hadIssue !== null) {
      params = params.set('hadIssue', hadIssue);
    }
    return this.http.get<ConsultationApiResponse<AdminRatingListResponse>>(`${this.base}/ratings`, { params });
  }

  /** GET /ratings/doctors — ملخص تقييمات الأطباء (متوسط + توزيع النجوم). */
  getDoctorRatingsSummary(): Observable<ConsultationApiResponse<AdminDoctorRatingSummaryResponse>> {
    return this.http.get<ConsultationApiResponse<AdminDoctorRatingSummaryResponse>>(`${this.base}/ratings/doctors`);
  }
}
