namespace Ajial.Application.DTOs.Consultation;

// ============================================================
// شاشة الأطباء المتاحين (استشارات طبية) + ملف الطبيب + بيانات الحجز
// ============================================================

/// <summary>كارت طبيب متاح في قائمة الأطباء (يملك عيادة و/أو كشف عن بعد مقبول).</summary>
public class AvailableDoctorResponse
{
    public Guid SpecialistId { get; set; }
    public string DoctorName { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public string Specialization { get; set; } = string.Empty;

    public bool HasClinic { get; set; }
    public bool HasRemote { get; set; }

    /// <summary>سعر الكشف داخل العيادة (لزر "حجز كشف داخل العيادة").</summary>
    public decimal? ClinicExaminationPrice { get; set; }

    /// <summary>سعر الجلسة اون لاين (لزر "حجز جلسة اون لاين").</summary>
    public decimal? RemoteSessionPrice { get; set; }
}

/// <summary>عنصر فلتر التخصص (شرائح "اسنان، تغذية ...").</summary>
public class SpecialtyChipResponse
{
    public string Specialization { get; set; } = string.Empty;
    public int DoctorCount { get; set; }
}

/// <summary>ملف الطبيب الشخصي كما يظهر لولي الأمر.</summary>
public class DoctorProfileResponse
{
    public Guid SpecialistId { get; set; }
    public string DoctorName { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public string Specialization { get; set; } = string.Empty;

    public bool HasClinic { get; set; }
    public bool HasRemote { get; set; }
    public decimal? ClinicExaminationPrice { get; set; }
    public decimal? RemoteSessionPrice { get; set; }

    // عنوان العيادة (من العيادة المقبولة إن وُجدت)
    public string? ClinicAddress { get; set; }
    public string? ClinicGovernorateName { get; set; }
}

/// <summary>بيانات تهيئة صفحة الحجز — حالة كل خدمة وتفاصيلها (للتبديل بين العيادة والاون لاين).</summary>
public class BookingInfoResponse
{
    public Guid SpecialistId { get; set; }
    public string DoctorName { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    public string Specialization { get; set; } = string.Empty;

    public ClinicServiceInfo? Clinic { get; set; }
    public RemoteServiceInfo? Remote { get; set; }
}

public class ClinicServiceInfo
{
    public Guid ClinicId { get; set; }
    public decimal? ExaminationPrice { get; set; }
    public decimal? ConsultationPrice { get; set; }
    public string? WorkingHoursJson { get; set; }
    public string? Address { get; set; }
    public string? GovernorateName { get; set; }
}

public class RemoteServiceInfo
{
    public Guid ConsultationId { get; set; }
    public decimal? SessionPrice { get; set; }
    public int? SessionDurationMinutes { get; set; }
    public int? WaitingPeriodMinutes { get; set; }
    public string? WorkingHoursJson { get; set; }
}

/// <summary>مواعيد يوم محدد لخدمة محددة.</summary>
public class DaySlotsResponse
{
    public string Date { get; set; } = string.Empty;       // yyyy-MM-dd
    public string ServiceType { get; set; } = string.Empty; // "clinic" | "remote"

    /// <summary>هل اليوم متاح للحجز (يوجد مواعيد عمل في هذا اليوم).</summary>
    public bool IsAvailable { get; set; }

    /// <summary>مواعيد الجلسات اون لاين (للكشف عن بعد فقط).</summary>
    public List<SlotDto> Slots { get; set; } = new();

    /// <summary>فترات عمل العيادة في هذا اليوم (للعيادة — الحجز باليوم فقط).</summary>
    public List<PeriodDto> WorkingPeriods { get; set; } = new();

    public string WorkingHoursText { get; set; } = string.Empty;
}

public class SlotDto
{
    public string StartTime { get; set; } = string.Empty; // HH:mm
    public string EndTime { get; set; } = string.Empty;   // HH:mm
    public bool IsBooked { get; set; }                     // محجوز
}

public class PeriodDto
{
    public string From { get; set; } = string.Empty; // HH:mm
    public string To { get; set; } = string.Empty;   // HH:mm
}

/// <summary>أقرب موعد متاح (زر "احجز اقرب موعد").</summary>
public class NearestSlotResponse
{
    public bool Found { get; set; }
    public string ServiceType { get; set; } = string.Empty;
    public string? Date { get; set; }       // yyyy-MM-dd
    public string? StartTime { get; set; }  // HH:mm (remote)
    public string? EndTime { get; set; }    // HH:mm (remote)
    public string? WorkingHoursText { get; set; } // (clinic)
}

/// <summary>خيار مريض في صفحة الحجز (ولي الأمر + أطفاله المفعّلين فقط).</summary>
public class PatientResponse
{
    /// <summary>معرّف الطفل — null يعني ولي الأمر نفسه.</summary>
    public Guid? ChildId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public bool IsSelf { get; set; }
}
