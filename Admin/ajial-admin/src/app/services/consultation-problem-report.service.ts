import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { ConsultationApiResponse } from '../models/consultation-payment.model';
import {
  AdminProblemReportListResponse,
  AdminProblemReportItem,
  UpdateProblemReportStatusRequest
} from '../models/consultation-problem-report.model';

@Injectable({ providedIn: 'root' })
export class ConsultationProblemReportService {
  private http = inject(HttpClient);
  private base = 'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api/admin/consultations';

  /** GET /problem-reports — قائمة بلاغات المشاكل (فلتر اختياري بالطبيب / الحالة / النوع). */
  getProblemReports(specialistId?: string, status?: number, category?: number, page = 1, pageSize = 100): Observable<ConsultationApiResponse<AdminProblemReportListResponse>> {
    let params = new HttpParams().set('page', page).set('pageSize', pageSize);
    if (specialistId) {
      params = params.set('specialistId', specialistId);
    }
    if (status !== undefined && status !== null) {
      params = params.set('status', status);
    }
    if (category !== undefined && category !== null) {
      params = params.set('category', category);
    }
    return this.http.get<ConsultationApiResponse<AdminProblemReportListResponse>>(`${this.base}/problem-reports`, { params });
  }

  /** GET /problem-reports/{id} — تفاصيل بلاغ مشكلة. */
  getProblemReport(reportId: string): Observable<ConsultationApiResponse<AdminProblemReportItem>> {
    return this.http.get<ConsultationApiResponse<AdminProblemReportItem>>(`${this.base}/problem-reports/${reportId}`);
  }

  /** PATCH /problem-reports/{id}/status — تحديث حالة بلاغ مشكلة. */
  updateStatus(reportId: string, body: UpdateProblemReportStatusRequest): Observable<ConsultationApiResponse<AdminProblemReportItem>> {
    return this.http.patch<ConsultationApiResponse<AdminProblemReportItem>>(`${this.base}/problem-reports/${reportId}/status`, body);
  }
}
