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
// لوحة الأدمن — الحجوزات الملغاة + متابعة استرداد المبالغ يدوياً
// ============================================================

/// <summary>قائمة الحجوزات الملغاة للوحة الأدمن (لمتابعة استرداد المبالغ يدوياً) مع ترقيم الصفحات.</summary>
public class AdminCancellationListResponse
{
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public List<AdminCancellationItemDto> Items { get; set; } = new();
}

/// <summary>حجز ملغى واحد كما يظهر للأدمن — يتضمن تفاصيل الاسترداد وصورة إيصال الدفع الأصلي ليتم الاسترداد يدوياً.</summary>
public class AdminCancellationItemDto
{
    public Guid BookingId { get; set; }

    public string ParentName { get; set; } = string.Empty;
    public string PatientName { get; set; } = string.Empty;
    public string DoctorName { get; set; } = string.Empty;
    public string ServiceTypeAr { get; set; } = string.Empty;
    public string AppointmentDate { get; set; } = string.Empty;

    /// <summary>قيمة الجلسة الأساسية.</summary>
    public decimal BasePrice { get; set; }

    /// <summary>نسبة رسوم الإلغاء (10%).</summary>
    public int CancellationFeePercent { get; set; }

    /// <summary>رسوم الإلغاء المخصومة.</summary>
    public decimal CancellationFeeAmount { get; set; }

    /// <summary>المبلغ الواجب استرداده لولي الأمر يدوياً.</summary>
    public decimal RefundAmount { get; set; }

    // ── الدفع الأصلي — ليتمكن الأدمن من إعادة المبلغ للرقم المُحوَّل منه (يظهر في صورة الإيصال) ──
    /// <summary>طريقة الدفع الأصلية (فودافون كاش / انستا باي) — null إذا لم يكن هناك دفع مرتبط.</summary>
    public string? PaymentMethod { get; set; }
    public string? PaymentMethodAr { get; set; }

    /// <summary>المبلغ المدفوع فعلياً (من الإيصال).</summary>
    public decimal? PaidAmount { get; set; }

    /// <summary>صورة إيصال الدفع الأصلي — يحتوي على الرقم المُحوَّل منه ولي الأمر لاسترداد المبلغ إليه.</summary>
    public string? ReceiptImageUrl { get; set; }

    /// <summary>حالة الدفع الأصلي (قيد المراجعة / تم القبول / مرفوض).</summary>
    public string? PaymentStatusAr { get; set; }

    public DateTime? CancelledAt { get; set; }
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

// ============================================================
// لوحة الأدمن — بلاغات المشاكل (الإبلاغ عن مشكلة تخص طبيباً)
// ============================================================

/// <summary>قائمة بلاغات المشاكل للوحة الأدمن مع ترقيم الصفحات وإحصاء سريع.</summary>
public class AdminProblemReportListResponse
{
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }

    /// <summary>عدد البلاغات الجديدة (لم تُراجع بعد) ضمن كل النتائج المطابقة للفلتر.</summary>
    public int NewCount { get; set; }

    public List<AdminProblemReportItemDto> Items { get; set; } = new();
}

/// <summary>بلاغ مشكلة واحد كما يظهر للأدمن.</summary>
public class AdminProblemReportItemDto
{
    public Guid ReportId { get; set; }

    // ── الطبيب المُبلَّغ عنه ──
    public Guid SpecialistId { get; set; }
    public string DoctorName { get; set; } = string.Empty;
    public string Specialization { get; set; } = string.Empty;
    public string? DoctorPhotoUrl { get; set; }

    // ── المُبلِّغ ──
    public Guid ParentId { get; set; }
    public string ParentName { get; set; } = string.Empty;

    // ── الجلسة المرتبطة (اختياري) ──
    public Guid? BookingId { get; set; }
    public string? ServiceTypeAr { get; set; }
    public string? AppointmentDate { get; set; }

    // ── محتوى البلاغ ──
    public int Category { get; set; }
    public string CategoryKey { get; set; } = string.Empty;
    public string CategoryAr { get; set; } = string.Empty;
    public string? Description { get; set; }

    // ── حالة المعالجة ──
    public int StatusValue { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public string? AdminNote { get; set; }
    public DateTime? ReviewedAt { get; set; }

    public DateTime CreatedAt { get; set; }
}

/// <summary>طلب تحديث حالة بلاغ مشكلة من الأدمن.</summary>
public class UpdateProblemReportStatusRequest
{
    /// <summary>الحالة الجديدة (0=جديد، 1=قيد المراجعة، 2=تم الحل).</summary>
    public int Status { get; set; }

    /// <summary>ملاحظة الأدمن (اختياري).</summary>
    public string? AdminNote { get; set; }
}
