export interface AdminClinicListItem {
  clinicId: string;
  clinicName: string | null;
  doctorName: string;
  status: string;
  statusAr: string;
  submittedAt: string | null;
}

export interface AdminClinicListResponse {
  totalCount: number;
  page: number;
  pageSize: number;
  items: AdminClinicListItem[];
}

export interface AdminClinicDetail {
  clinicId: string;
  specialistId: string;
  doctorName: string;
  status: string;
  statusAr: string;
  submittedAt: string | null;
  rejectionReason: string | null;
  name: string | null;
  governorateName: string | null;
  districtName: string | null;
  address: string | null;
  phone: string | null;
  workingHoursJson: string | null;
  examinationPrice: number | null;
  consultationPrice: number | null;
  licenseImageUrl: string | null;
  syndicateRegistrationImageUrl: string | null;
  hazardousWasteImageUrl: string | null;
  exteriorImageUrl: string | null;
  interiorImageUrl: string | null;
}

export interface AdminRemoteConsultationListItem {
  consultationId: string;
  doctorName: string;
  status: string;
  statusAr: string;
  submittedAt: string | null;
}

export interface AdminRemoteConsultationListResponse {
  totalCount: number;
  page: number;
  pageSize: number;
  items: AdminRemoteConsultationListItem[];
}

export interface AdminRemoteConsultationDetail {
  consultationId: string;
  specialistId: string;
  doctorName: string;
  status: string;
  statusAr: string;
  submittedAt: string | null;
  rejectionReason: string | null;
  sessionPrice: number | null;
  sessionDurationMinutes: number | null;
  waitingPeriodMinutes: number | null;
  workingHoursJson: string | null;
}

export interface ClinicApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}
