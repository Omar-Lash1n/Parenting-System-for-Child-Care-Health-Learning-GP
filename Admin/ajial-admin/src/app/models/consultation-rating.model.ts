// نماذج تقييمات الجلسات (لوحة الأدمن) — مطابقة لاستجابة الـ API.

export interface AdminRatingItem {
  ratingId: string;
  bookingId: string;
  specialistId: string;
  doctorName: string;
  specialization: string;
  parentName: string;
  patientName: string;
  serviceTypeAr: string;
  appointmentDate: string;
  rating: number;            // 1..5
  wouldBookAgain: boolean;
  wouldBookAgainAr: string;
  hadIssue: boolean;
  issueDescription: string | null;
  starsAwarded: number;
  createdAt: string;
}

export interface AdminRatingListResponse {
  totalCount: number;
  page: number;
  pageSize: number;
  averageRating: number;
  items: AdminRatingItem[];
}

export interface AdminDoctorRating {
  specialistId: string;
  doctorName: string;
  specialization: string;
  photoUrl: string | null;
  averageRating: number;
  totalRatings: number;
  fiveStars: number;
  fourStars: number;
  threeStars: number;
  twoStars: number;
  oneStar: number;
  wouldBookAgainCount: number;
  issuesCount: number;
}

export interface AdminDoctorRatingSummaryResponse {
  doctorCount: number;
  overallAverageRating: number;
  totalRatings: number;
  doctors: AdminDoctorRating[];
}
