import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Child {
  childId: string;
  childFullName: string;
  childBirthDate: string;
  childAge: number;
  childGender: string;
  childProfileImageUrl: string;
  childLoginId: string | null;
  childHasAccount: boolean;
  childIsActive: boolean;
  childCreatedAt: string;
  childUpdatedAt: string;
  parentId: string;
  parentUserId: string;
  parentFullName: string;
  parentUsername: string;
  parentEmail: string;
  parentGender: string;
  parentDateOfBirth: string;
  parentAge: number;
  parentIsActive: boolean;
  parentCreatedAt: string;
  cityId: number;
  cityName: string;
  cityNameAr: string;
  ageGroup: string;
  daysSinceRegistration: number;
  registrationMonth: string;
  registrationYear: string;
}

export interface Parent {
  userId: string;
  fullName: string;
  username: string;
  email: string;
  userCreatedAt: string;
  userUpdatedAt: string | null;
  parentId: string;
  dateOfBirth: string;
  age: number;
  gender: string;
  genderCode: number;
  cityId: number;
  cityName: string;
  cityNameAr: string;
  cityIsActive: boolean;
  accountAgeInDays: number;
  ageGroup: string;
  region: string;
}

export interface ParentSummary {
  totalParents: number;
  maleCount: number;
  femaleCount: number;
  averageAge: number;
  ageGroups: { ageGroup: string; count: number }[];
  citiesDistribution: { city: string; count: number }[];
  regionsDistribution: { region: string; count: number }[];
  recentRegistrations: number;
  lastUpdated: string;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  errors: any;
}

@Injectable({
  providedIn: 'root'
})
export class AnalyticsService {
  private http = inject(HttpClient);
  private baseUrl = 'https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api';

  getChildrenAnalytics(): Observable<ApiResponse<Child[]>> {
    return this.http.get<ApiResponse<Child[]>>(`${this.baseUrl}/Analytics/children`);
  }

  getParentsAnalytics(): Observable<ApiResponse<Parent[]>> {
    return this.http.get<ApiResponse<Parent[]>>(`${this.baseUrl}/Parents/analytics`);
  }

  getParentsSummary(): Observable<ApiResponse<ParentSummary>> {
    return this.http.get<ApiResponse<ParentSummary>>(`${this.baseUrl}/Parents/analytics/summary`);
  }

  getChildProfileSummary(childId: string): Observable<ApiResponse<any>> {
    return this.http.get<ApiResponse<any>>(`${this.baseUrl}/Parents/child/${childId}/profile-summary`);
  }
}
