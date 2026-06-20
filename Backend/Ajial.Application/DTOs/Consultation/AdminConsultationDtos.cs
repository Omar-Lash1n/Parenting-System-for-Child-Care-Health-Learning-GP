namespace Ajial.Application.DTOs.Consultation;

// ============================================================
// لوحة الأدمن — مراجعة المدفوعات + إعدادات أرقام الدفع
// ============================================================

public class AdminPaymentListResponse
{
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public List<AdminPaymentListItemDto> Items { get; set; } = new();
}

public class AdminPaymentListItemDto
{
    public Guid PaymentId { get; set; }
    public Guid BookingId { get; set; }
    public string ParentName { get; set; } = string.Empty;
    public string DoctorName { get; set; } = string.Empty;
    public string ServiceTypeAr { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Method { get; set; } = string.Empty;
    public string MethodAr { get; set; } = string.Empty;
    public string ReceiptImageUrl { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class AdminPaymentDetailResponse
{
    public Guid PaymentId { get; set; }
    public Guid BookingId { get; set; }

    public string ParentName { get; set; } = string.Empty;
    public string PatientName { get; set; } = string.Empty;
    public string DoctorName { get; set; } = string.Empty;
    public string Specialization { get; set; } = string.Empty;

    public string ServiceTypeAr { get; set; } = string.Empty;
    public string AppointmentDate { get; set; } = string.Empty;
    public string? StartTime { get; set; }
    public string? EndTime { get; set; }

    public decimal Amount { get; set; }
    public string Method { get; set; } = string.Empty;
    public string MethodAr { get; set; } = string.Empty;
    public string ReceiptImageUrl { get; set; } = string.Empty;

    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public string? RejectionReason { get; set; }

    public string BookingStatus { get; set; } = string.Empty;
    public string BookingStatusAr { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
}

public class PaymentStatusChangeResponse
{
    public Guid PaymentId { get; set; }
    public Guid BookingId { get; set; }
    public string PaymentStatus { get; set; } = string.Empty;
    public string PaymentStatusAr { get; set; } = string.Empty;
    public string BookingStatus { get; set; } = string.Empty;
    public string BookingStatusAr { get; set; } = string.Empty;
}

public class RejectPaymentRequest
{
    public string Reason { get; set; } = string.Empty;
}

public class PaymentSettingsResponse
{
    public string VodafoneCashNumber { get; set; } = string.Empty;
    public string InstaPayNumber { get; set; } = string.Empty;
}

public class UpdatePaymentSettingsRequest
{
    public string? VodafoneCashNumber { get; set; }
    public string? InstaPayNumber { get; set; }
}

// ============================================================
// لوحة الأدمن — تقييمات الجلسات (تقييم الأطباء + استبيانات ولي الأمر)
// ============================================================

/// <summary>قائمة استبيانات تقييم الجلسات (كل تقييم فردي) مع ترقيم الصفحات.</summary>
public class AdminRatingListResponse
{
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }

    /// <summary>متوسط تقييم النجوم لكل النتائج المطابقة للفلتر (وليس للصفحة فقط).</summary>
    public double AverageRating { get; set; }

    public List<AdminRatingItemDto> Items { get; set; } = new();
}

/// <summary>استبيان تقييم جلسة واحد كما يظهر للأدمن.</summary>
public class AdminRatingItemDto
{
    public Guid RatingId { get; set; }
    public Guid BookingId { get; set; }

    public Guid SpecialistId { get; set; }
    public string DoctorName { get; set; } = string.Empty;
    public string Specialization { get; set; } = string.Empty;

    public string ParentName { get; set; } = string.Empty;
    public string PatientName { get; set; } = string.Empty;
    public string ServiceTypeAr { get; set; } = string.Empty;
    public string AppointmentDate { get; set; } = string.Empty;

    /// <summary>تقييم النجوم 1..5.</summary>
    public int Rating { get; set; }

    /// <summary>هل ستعاود طلب الجلسة مرة اخرى؟</summary>
    public bool WouldBookAgain { get; set; }
    public string WouldBookAgainAr { get; set; } = string.Empty;

    /// <summary>هل واجهت اى مشكلة اثناء الجلسة او الحجز؟</summary>
    public bool HadIssue { get; set; }
    public string? IssueDescription { get; set; }

    public int StarsAwarded { get; set; }
    public DateTime CreatedAt { get; set; }
}

/// <summary>ملخص تقييمات الأطباء (مجمّع لكل طبيب) للوحة الأدمن.</summary>
public class AdminDoctorRatingSummaryResponse
{
    public int DoctorCount { get; set; }

    /// <summary>متوسط تقييم كل الجلسات المُقيَّمة عبر كل الأطباء.</summary>
    public double OverallAverageRating { get; set; }
    public int TotalRatings { get; set; }

    public List<AdminDoctorRatingDto> Doctors { get; set; } = new();
}

/// <summary>إحصائيات تقييم طبيب واحد.</summary>
public class AdminDoctorRatingDto
{
    public Guid SpecialistId { get; set; }
    public string DoctorName { get; set; } = string.Empty;
    public string Specialization { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }

    /// <summary>متوسط تقييم النجوم لهذا الطبيب.</summary>
    public double AverageRating { get; set; }
    public int TotalRatings { get; set; }

    // توزيع النجوم
    public int FiveStars { get; set; }
    public int FourStars { get; set; }
    public int ThreeStars { get; set; }
    public int TwoStars { get; set; }
    public int OneStar { get; set; }

    /// <summary>عدد من قال "نعم سأعاود طلب الجلسة".</summary>
    public int WouldBookAgainCount { get; set; }

    /// <summary>عدد من أبلغ عن مشكلة أثناء الجلسة او الحجز.</summary>
    public int IssuesCount { get; set; }
}
