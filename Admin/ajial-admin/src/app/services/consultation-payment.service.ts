import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import {
  ConsultationApiResponse,
  AdminPaymentListResponse,
  AdminPaymentDetail,
  PaymentStatusChangeResponse,
  PaymentSettingsResponse,
  UpdatePaymentSettingsRequest,
  AdminCancellationListResponse
} from '../models/consultation-payment.model';

@Injectable({ providedIn: 'root' })
export class ConsultationPaymentService {
  private http = inject(HttpClient);
  private base = 'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api/admin/consultations';

  getPayments(status?: number, page = 1, pageSize = 100): Observable<ConsultationApiResponse<AdminPaymentListResponse>> {
    let params = new HttpParams().set('page', page).set('pageSize', pageSize);
    if (status !== undefined && status !== null) {
      params = params.set('status', status);
    }
    return this.http.get<ConsultationApiResponse<AdminPaymentListResponse>>(`${this.base}/payments`, { params });
  }

  getPayment(id: string): Observable<ConsultationApiResponse<AdminPaymentDetail>> {
    return this.http.get<ConsultationApiResponse<AdminPaymentDetail>>(`${this.base}/payments/${id}`);
  }

  approvePayment(id: string): Observable<ConsultationApiResponse<PaymentStatusChangeResponse>> {
    return this.http.post<ConsultationApiResponse<PaymentStatusChangeResponse>>(`${this.base}/payments/${id}/approve`, {});
  }

  rejectPayment(id: string, reason: string): Observable<ConsultationApiResponse<PaymentStatusChangeResponse>> {
    return this.http.post<ConsultationApiResponse<PaymentStatusChangeResponse>>(`${this.base}/payments/${id}/reject`, { reason });
  }

  getCancellations(page = 1, pageSize = 100): Observable<ConsultationApiResponse<AdminCancellationListResponse>> {
    const params = new HttpParams().set('page', page).set('pageSize', pageSize);
    return this.http.get<ConsultationApiResponse<AdminCancellationListResponse>>(`${this.base}/cancellations`, { params });
  }

  getPaymentSettings(): Observable<ConsultationApiResponse<PaymentSettingsResponse>> {
    return this.http.get<ConsultationApiResponse<PaymentSettingsResponse>>(`${this.base}/payment-settings`);
  }

  updatePaymentSettings(request: UpdatePaymentSettingsRequest): Observable<ConsultationApiResponse<PaymentSettingsResponse>> {
    return this.http.put<ConsultationApiResponse<PaymentSettingsResponse>>(`${this.base}/payment-settings`, request);
  }
}
