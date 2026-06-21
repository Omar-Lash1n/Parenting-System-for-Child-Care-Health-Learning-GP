namespace Ajial.Application.DTOs.Consultation;

// ============================================================
// استشارات طبية — جانب الطبيب (المرحلة الرابعة)
// عرض المواعيد المحجوزة، تفاصيل الحجز، والتحكم في جلسة الكشف اون لاين.
// ============================================================

/// <summary>مواعيد اليوم المحدد لجانب الطبيب مع حالة كل موعد (محجوز / متاح).</summary>
public class DoctorDaySlotsResponse
{
    public string Date { get; set; } = string.Empty; // yyyy-MM-dd
    public bool IsAvailable { get; set; }
    public List<DoctorSlotDto> Slots { get; set; } = new();
}

/// <summary>موعد واحد في يوم الطبيب — يحمل بيانات الحجز إن كان محجوزاً.</summary>
public class DoctorSlotDto
{
    public string StartTime { get; set; } = string.Empty; // HH:mm
    public string EndTime { get; set; } = string.Empty;   // HH:mm

    /// <summary>هل الموعد محجوز (يوجد حجز مؤكَّد أو مكتمل من ولي الأمر).</summary>
    public bool IsBooked { get; set; }

    /// <summary>معرّف الحجز — يُملأ فقط للمواعيد المحجوزة (لفتح تفاصيل الحجز).</summary>
    public Guid? BookingId { get; set; }

    public string? PatientName { get; set; }

    /// <summary>مفتاح حالة الحجز (confirmed / completed) للمواعيد المحجوزة.</summary>
    public string? Status { get; set; }

    /// <summary>تسمية الحالة بالعربية (جاري المعالجة / جلسة مكتملة).</summary>
    public string? StatusAr { get; set; }
}

/// <summary>الأيام التي تحتوي على حجوزات خلال شهر — لإظهار النقطة على التقويم.</summary>
public class DoctorCalendarResponse
{
    public string Month { get; set; } = string.Empty; // yyyy-MM
    public List<string> BookedDates { get; set; } = new(); // yyyy-MM-dd
}

/// <summary>
/// تفاصيل الحجز الكاملة لجانب الطبيب — بيانات المريض، الشكوى، المرفقات، الملف الطبي،
/// بالإضافة لحالة الجلسة. تُغذّي شاشتَي تفاصيل الحجز والأعراض والشكوى.
/// </summary>
public class DoctorBookingDetailResponse
{
    public Guid BookingId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;

    public string ServiceType { get; set; } = string.Empty;
    public string ServiceTypeAr { get; set; } = string.Empty;

    public string AppointmentDate { get; set; } = string.Empty; // yyyy-MM-dd
    public string? StartTime { get; set; }
    public string? EndTime { get; set; }
    public int? DurationMinutes { get; set; }
    public decimal Price { get; set; }

    // ── المريض ──
    public Guid? ChildId { get; set; }
    public bool IsChildPatient { get; set; }
    public string PatientName { get; set; } = string.Empty;
    public string? PatientImageUrl { get; set; }
    public int? PatientAge { get; set; }
    public string? PatientGender { get; set; }

    // ── الأعراض والشكوى ──
    public string? ComplaintDescription { get; set; }
    public List<AttachmentDto> Attachments { get; set; } = new();
    public bool ShareMedicalFile { get; set; }

    /// <summary>رابط الملف الطبي الموحد للطفل (PDF) إذا شاركه ولي الأمر عند الحجز.</summary>
    public string? MedicalFileUrl { get; set; }

    // ── حالة الجلسة (للتحكم في زر بدء/إنهاء الجلسة) ──
    public DoctorSessionStatusResponse Session { get; set; } = new();
}

/// <summary>
/// حالة جلسة الكشف اون لاين لجانب الطبيب — تُستخدم للعدّ التنازلي وتفعيل أزرار
/// بدء/إنهاء الجلسة. الشارة (StatusAr) تعتمد على حالة الحجز فقط، والأزرار تعتمد على
/// ما إذا كانت الجلسة قد بدأت فعلياً.
/// </summary>
public class DoctorSessionStatusResponse
{
    public Guid BookingId { get; set; }

    public string Status { get; set; } = string.Empty;

    /// <summary>شارة الحالة: "جاري المعالجة" (مؤكَّد) أو "جلسة مكتملة" (مكتمل).</summary>
    public string StatusAr { get; set; } = string.Empty;

    public string AppointmentDate { get; set; } = string.Empty; // yyyy-MM-dd
    public string? StartTime { get; set; }
    public string? EndTime { get; set; }
    public int? DurationMinutes { get; set; }

    /// <summary>التوقيت الحالي للخادم بتوقيت مصر — مرجع لحساب العدّ التنازلي.</summary>
    public DateTime ServerTimeEgypt { get; set; }

    /// <summary>عدد الثواني حتى بداية الموعد (سالب إذا حلّ الموعد بالفعل).</summary>
    public long SecondsUntilStart { get; set; }

    /// <summary>عدد الثواني حتى نهاية الموعد (سالب إذا انتهى الوقت).</summary>
    public long SecondsUntilEnd { get; set; }

    /// <summary>هل بدأ الطبيب الجلسة فعلياً (تم إنشاء رابط Meet).</summary>
    public bool SessionStarted { get; set; }

    /// <summary>هل انتهت الجلسة (الحالة = مكتملة).</summary>
    public bool SessionEnded { get; set; }

    /// <summary>هل يمكن للطبيب بدء الجلسة الآن (مؤكَّد + لم تبدأ + ضمن النافذة الزمنية).</summary>
    public bool CanStart { get; set; }

    /// <summary>هل يمكن للطبيب إنهاء الجلسة الآن (مؤكَّد + بدأت بالفعل).</summary>
    public bool CanEnd { get; set; }

    /// <summary>رابط الانضمام لـ Google Meet — يُملأ فقط أثناء جلسة قائمة (بدأت ولم تنتهِ).</summary>
    public string? JoinUrl { get; set; }
}

// ============================================================
// الملف الشخصي للطبيب (كما يراه الطبيب نفسه)
// البيانات الأساسية + مستندات التوثيق + ملخص الخدمات + الإحصائيات.
// ============================================================

/// <summary>
/// الملف الشخصي الكامل للطبيب كما يراه الطبيب نفسه: البيانات الأساسية، مستندات التوثيق،
/// ملخص الخدمات المتاحة (عيادة / كشف عن بعد)، وإحصائيات الحجوزات والتقييم.
/// </summary>
public class DoctorOwnProfileResponse
{
    // ── البيانات الأساسية ──
    public Guid SpecialistId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public bool IsEmailVerified { get; set; }
    public string Phone { get; set; } = string.Empty;
    public string Specialization { get; set; } = string.Empty;
    public string PracticeLicenseNumber { get; set; } = string.Empty;
    public string? PersonalPhotoUrl { get; set; }

    /// <summary>مفتاح حالة حساب الطبيب (draft / pending / approved / rejected / cancelled).</summary>
    public string Status { get; set; } = string.Empty;

    /// <summary>تسمية حالة الحساب بالعربية.</summary>
    public string StatusAr { get; set; } = string.Empty;

    /// <summary>سبب الرفض — يُملأ فقط عندما تكون الحالة مرفوضة.</summary>
    public string? RejectionReason { get; set; }

    public DateTime CreatedAt { get; set; }

    // ── مستندات التوثيق ──
    public DoctorVerificationDocuments Documents { get; set; } = new();

    // ── ملخص الخدمات ──
    public DoctorServicesSummary Services { get; set; } = new();

    // ── الإحصائيات ──
    public DoctorProfileStats Stats { get; set; } = new();
}

/// <summary>روابط مستندات التوثيق الستة التي رفعها الطبيب عند التسجيل.</summary>
public class DoctorVerificationDocuments
{
    public string? IdFrontImageUrl { get; set; }
    public string? IdBackImageUrl { get; set; }
    public string? SpecializationCertificateImageUrl { get; set; }
    public string? PracticeLicenseImageUrl { get; set; }
    public string? UnionCardImageUrl { get; set; }
    public string? PersonalPhotoUrl { get; set; }
}

/// <summary>ملخص الخدمات المقبولة للطبيب (عيادة و/أو كشف عن بعد).</summary>
public class DoctorServicesSummary
{
    public bool HasClinic { get; set; }
    public bool HasRemote { get; set; }
    public DoctorClinicSummary? Clinic { get; set; }
    public DoctorRemoteSummary? Remote { get; set; }
}

public class DoctorClinicSummary
{
    public Guid ClinicId { get; set; }
    public string? Name { get; set; }
    public string? Address { get; set; }
    public string? GovernorateName { get; set; }
    public decimal? ExaminationPrice { get; set; }
    public decimal? ConsultationPrice { get; set; }
}

public class DoctorRemoteSummary
{
    public Guid ConsultationId { get; set; }
    public decimal? SessionPrice { get; set; }
    public int? SessionDurationMinutes { get; set; }
    public int? WaitingPeriodMinutes { get; set; }
}

/// <summary>إحصائيات سريعة لملف الطبيب — عدد الحجوزات، الجلسات المكتملة، ومتوسط التقييم.</summary>
public class DoctorProfileStats
{
    /// <summary>إجمالي حجوزات الطبيب (كل الحالات).</summary>
    public int TotalBookings { get; set; }

    /// <summary>عدد الحجوزات المؤكَّدة القادمة (لم تكتمل بعد).</summary>
    public int UpcomingBookings { get; set; }

    /// <summary>عدد الجلسات/الحجوزات المكتملة.</summary>
    public int CompletedSessions { get; set; }

    /// <summary>عدد التقييمات التي حصل عليها الطبيب.</summary>
    public int RatingsCount { get; set; }

    /// <summary>متوسط التقييم بالنجوم (0 إذا لم يُقيَّم بعد).</summary>
    public double AverageRating { get; set; }
}
