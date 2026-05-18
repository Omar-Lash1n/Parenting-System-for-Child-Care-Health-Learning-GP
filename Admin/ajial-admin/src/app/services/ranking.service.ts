import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import {
  ApiResponse,
  PagedAdminCurrentRanking,
  PublishRankingRequest,
  PublishedRanking,
  AdminPublishedRanking
} from '../models/ranking.model';

@Injectable({ providedIn: 'root' })
export class RankingService {
  private http = inject(HttpClient);
  private baseUrl = 'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api/admin/ranking';

  getCurrentRanking(page = 1, pageSize = 20): Observable<ApiResponse<PagedAdminCurrentRanking>> {
    return this.http.get<ApiResponse<PagedAdminCurrentRanking>>(
      `${this.baseUrl}/current`,
      { params: { page: page.toString(), pageSize: pageSize.toString() } }
    );
  }

  publishRanking(dto: PublishRankingRequest): Observable<ApiResponse<PublishedRanking>> {
    return this.http.post<ApiResponse<PublishedRanking>>(`${this.baseUrl}/publish`, dto);
  }

  getRankingHistory(): Observable<ApiResponse<AdminPublishedRanking[]>> {
    return this.http.get<ApiResponse<AdminPublishedRanking[]>>(`${this.baseUrl}/history`);
  }
}
