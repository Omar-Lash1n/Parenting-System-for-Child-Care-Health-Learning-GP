export interface AdminPaymentListItem {
  paymentId: string;
  bookingId: string;
  parentName: string;
  doctorName: string;
  serviceTypeAr: string;
  amount: number;
  method: string;
  methodAr: string;
  receiptImageUrl: string;
  status: string;
  statusAr: string;
  createdAt: string;
}

export interface AdminPaymentListResponse {
  totalCount: number;
  page: number;
  pageSize: number;
  items: AdminPaymentListItem[];
}

export interface AdminPaymentDetail {
  paymentId: string;
  bookingId: string;
  parentName: string;
  patientName: string;
  doctorName: string;
  specialization: string;
  serviceTypeAr: string;
  appointmentDate: string;
  startTime: string | null;
  endTime: string | null;
  amount: number;
  method: string;
  methodAr: string;
  receiptImageUrl: string;
  status: string;
  statusAr: string;
  rejectionReason: string | null;
  bookingStatus: string;
  bookingStatusAr: string;
  createdAt: string;
}

export interface PaymentStatusChangeResponse {
  paymentId: string;
  bookingId: string;
  paymentStatus: string;
  paymentStatusAr: string;
  bookingStatus: string;
  bookingStatusAr: string;
}

export interface PaymentSettingsResponse {
  vodafoneCashNumber: string;
  instaPayNumber: string;
}

export interface UpdatePaymentSettingsRequest {
  vodafoneCashNumber?: string;
  instaPayNumber?: string;
}

export interface ConsultationApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}
