import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import {
  ApiResponse,
  CreateDailyQuestionRequest,
  DailyQuestionAdminDto,
  DailyQuestionListDto,
  UpdateDailyQuestionRequest
} from '../models/daily-question.model';

@Injectable({
  providedIn: 'root'
})
export class DailyQuestionsService {
  private http = inject(HttpClient);
  private baseUrl = 'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api/admin/daily-questions';

  getAll(isActive?: boolean): Observable<ApiResponse<DailyQuestionListDto[]>> {
    const options = isActive === undefined ? {} : { params: new HttpParams().set('isActive', isActive) };
    return this.http.get<ApiResponse<DailyQuestionListDto[]>>(this.baseUrl, options);
  }

  getById(questionId: string): Observable<ApiResponse<DailyQuestionAdminDto>> {
    return this.http.get<ApiResponse<DailyQuestionAdminDto>>(`${this.baseUrl}/${questionId}`);
  }

  create(dto: CreateDailyQuestionRequest): Observable<ApiResponse<DailyQuestionAdminDto>> {
    return this.http.post<ApiResponse<DailyQuestionAdminDto>>(this.baseUrl, dto);
  }

  update(questionId: string, dto: UpdateDailyQuestionRequest): Observable<ApiResponse<DailyQuestionAdminDto>> {
    return this.http.put<ApiResponse<DailyQuestionAdminDto>>(`${this.baseUrl}/${questionId}`, dto);
  }

  delete(questionId: string): Observable<ApiResponse<boolean>> {
    return this.http.delete<ApiResponse<boolean>>(`${this.baseUrl}/${questionId}`);
  }

  activate(questionId: string): Observable<ApiResponse<DailyQuestionAdminDto>> {
    return this.http.patch<ApiResponse<DailyQuestionAdminDto>>(`${this.baseUrl}/${questionId}/activate`, {});
  }

  deactivate(questionId: string): Observable<ApiResponse<DailyQuestionAdminDto>> {
    return this.http.patch<ApiResponse<DailyQuestionAdminDto>>(`${this.baseUrl}/${questionId}/deactivate`, {});
  }

  resetAll(): Observable<ApiResponse<boolean>> {
    return this.http.post<ApiResponse<boolean>>(`${this.baseUrl}/reset`, {});
  }
}
