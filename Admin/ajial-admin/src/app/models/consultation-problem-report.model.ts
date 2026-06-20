// نماذج بلاغات المشاكل (لوحة الأدمن) — مطابقة لاستجابة الـ API.

export interface AdminProblemReportItem {
  reportId: string;

  specialistId: string;
  doctorName: string;
  specialization: string;
  doctorPhotoUrl: string | null;

  parentId: string;
  parentName: string;

  bookingId: string | null;
  serviceTypeAr: string | null;
  appointmentDate: string | null;

  category: number;          // 1..4
  categoryKey: string;
  categoryAr: string;
  description: string | null;

  statusValue: number;       // 0=جديد، 1=قيد المراجعة، 2=تم الحل
  status: string;
  statusAr: string;
  adminNote: string | null;
  reviewedAt: string | null;

  createdAt: string;
}

export interface AdminProblemReportListResponse {
  totalCount: number;
  page: number;
  pageSize: number;
  newCount: number;
  items: AdminProblemReportItem[];
}

export interface UpdateProblemReportStatusRequest {
  status: number;            // 0 | 1 | 2
  adminNote?: string | null;
}
