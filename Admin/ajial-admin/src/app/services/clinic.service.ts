import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import {
  ClinicApiResponse,
  AdminClinicListResponse,
  AdminClinicDetail,
  AdminRemoteConsultationListResponse,
  AdminRemoteConsultationDetail
} from '../models/clinic.model';

@Injectable({ providedIn: 'root' })
export class ClinicService {
  private http = inject(HttpClient);
  private base = 'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api/admin';

  getClinics(page = 1, pageSize = 100): Observable<ClinicApiResponse<AdminClinicListResponse>> {
    const params = new HttpParams().set('page', page).set('pageSize', pageSize);
    return this.http.get<ClinicApiResponse<AdminClinicListResponse>>(`${this.base}/clinics`, { params });
  }

  getClinic(id: string): Observable<ClinicApiResponse<AdminClinicDetail>> {
    return this.http.get<ClinicApiResponse<AdminClinicDetail>>(`${this.base}/clinics/${id}`);
  }

  approveClinic(id: string): Observable<ClinicApiResponse<any>> {
    return this.http.post<ClinicApiResponse<any>>(`${this.base}/clinics/${id}/approve`, {});
  }

  rejectClinic(id: string, reason: string): Observable<ClinicApiResponse<any>> {
    return this.http.post<ClinicApiResponse<any>>(`${this.base}/clinics/${id}/reject`, { reason });
  }

  getConsultations(page = 1, pageSize = 100): Observable<ClinicApiResponse<AdminRemoteConsultationListResponse>> {
    const params = new HttpParams().set('page', page).set('pageSize', pageSize);
    return this.http.get<ClinicApiResponse<AdminRemoteConsultationListResponse>>(`${this.base}/remote-consultations`, { params });
  }

  getConsultation(id: string): Observable<ClinicApiResponse<AdminRemoteConsultationDetail>> {
    return this.http.get<ClinicApiResponse<AdminRemoteConsultationDetail>>(`${this.base}/remote-consultations/${id}`);
  }

  approveConsultation(id: string): Observable<ClinicApiResponse<any>> {
    return this.http.post<ClinicApiResponse<any>>(`${this.base}/remote-consultations/${id}/approve`, {});
  }

  rejectConsultation(id: string, reason: string): Observable<ClinicApiResponse<any>> {
    return this.http.post<ClinicApiResponse<any>>(`${this.base}/remote-consultations/${id}/reject`, { reason });
  }
}
