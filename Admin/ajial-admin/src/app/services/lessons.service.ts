import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import {
  ApiResponse,
  LessonCategoryDto,
  CreateLessonCategoryRequest,
  UpdateLessonCategoryRequest,
  LessonAdminListDto,
  LessonAdminDetailDto,
  CreateLessonRequest,
  UpdateLessonRequest
} from '../models/lesson.model';

@Injectable({ providedIn: 'root' })
export class LessonsService {
  private http = inject(HttpClient);
  private baseUrl = 'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api/admin/lessons';

  getCategories(isActive?: boolean): Observable<ApiResponse<LessonCategoryDto[]>> {
    const options = isActive === undefined ? {} : { params: new HttpParams().set('isActive', isActive) };
    return this.http.get<ApiResponse<LessonCategoryDto[]>>(`${this.baseUrl}/categories`, options);
  }

  createCategory(dto: CreateLessonCategoryRequest): Observable<ApiResponse<LessonCategoryDto>> {
    return this.http.post<ApiResponse<LessonCategoryDto>>(`${this.baseUrl}/categories`, dto);
  }

  updateCategory(id: string, dto: UpdateLessonCategoryRequest): Observable<ApiResponse<LessonCategoryDto>> {
    return this.http.put<ApiResponse<LessonCategoryDto>>(`${this.baseUrl}/categories/${id}`, dto);
  }

  deleteCategory(id: string): Observable<ApiResponse<boolean>> {
    return this.http.delete<ApiResponse<boolean>>(`${this.baseUrl}/categories/${id}`);
  }

  getLessons(categoryId?: string, isActive?: boolean): Observable<ApiResponse<LessonAdminListDto[]>> {
    let params = new HttpParams();
    if (categoryId) params = params.set('categoryId', categoryId);
    if (isActive !== undefined) params = params.set('isActive', isActive);
    return this.http.get<ApiResponse<LessonAdminListDto[]>>(this.baseUrl, { params });
  }

  getLessonById(id: string): Observable<ApiResponse<LessonAdminDetailDto>> {
    return this.http.get<ApiResponse<LessonAdminDetailDto>>(`${this.baseUrl}/${id}`);
  }

  createLesson(dto: CreateLessonRequest): Observable<ApiResponse<LessonAdminDetailDto>> {
    return this.http.post<ApiResponse<LessonAdminDetailDto>>(this.baseUrl, dto);
  }

  updateLesson(id: string, dto: UpdateLessonRequest): Observable<ApiResponse<LessonAdminDetailDto>> {
    return this.http.put<ApiResponse<LessonAdminDetailDto>>(`${this.baseUrl}/${id}`, dto);
  }

  deleteLesson(id: string): Observable<ApiResponse<boolean>> {
    return this.http.delete<ApiResponse<boolean>>(`${this.baseUrl}/${id}`);
  }

  activateLesson(id: string): Observable<ApiResponse<LessonAdminDetailDto>> {
    return this.http.patch<ApiResponse<LessonAdminDetailDto>>(`${this.baseUrl}/${id}/activate`, {});
  }

  deactivateLesson(id: string): Observable<ApiResponse<LessonAdminDetailDto>> {
    return this.http.patch<ApiResponse<LessonAdminDetailDto>>(`${this.baseUrl}/${id}/deactivate`, {});
  }
}
