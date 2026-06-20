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

// ── الحجوزات الملغاة + متابعة استرداد المبالغ يدوياً ──

export interface AdminCancellationItem {
  bookingId: string;
  parentName: string;
  patientName: string;
  doctorName: string;
  serviceTypeAr: string;
  appointmentDate: string;
  basePrice: number;
  cancellationFeePercent: number;
  cancellationFeeAmount: number;
  refundAmount: number;
  paymentMethod: string | null;
  paymentMethodAr: string | null;
  paidAmount: number | null;
  receiptImageUrl: string | null;
  paymentStatusAr: string | null;
  cancelledAt: string | null;
}

export interface AdminCancellationListResponse {
  totalCount: number;
  page: number;
  pageSize: number;
  items: AdminCancellationItem[];
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
