namespace Ajial.Domain.Entities;

public enum UserType
{
    Parent = 1,
    Doctor = 2,
    Child = 3
}

public enum ParentGender
{
    Father = 1,  // أب
    Mother = 2,  // أم
    Educator  = 3    // مربي
}

public enum SpecialistStatus
{
    Draft = 0,      // مسودة
    Pending = 1,    // في انتظار مراجعة الإدارة
    Approved = 2,   // تمت الموافقة
    Rejected = 3,   // مرفوض
    Cancelled = 4   // تم الغاء الطلب
}

public enum SpecialistDocumentType
{
    NationalIdFront = 1,
    NationalIdBack = 2,
    PersonalPhoto = 3,
    SpecializationCertificate = 4,
    ProfessionalLicense = 5,
    SyndicateCard = 6
}

public enum HealthUnitType
{
    HealthUnit = 1,          // وحدة صحية
    Hospital = 2,            // مستشفى
    VaccinationCenter = 3    // مركز تطعيم
}

public enum ClinicStatus
{
    Draft = 0,      // مسودة
    Pending = 1,    // قيد المراجعة
    Approved = 2,   // تمت الموافقة
    Rejected = 3,   // مرفوض
    Cancelled = 4   // ملغي
}

public enum ClinicDocumentType
{
    LicenseImage = 1,               // صورة ترخيص العيادة
    SyndicateRegistrationImage = 2, // شهادة تسجيل العيادة بالنقابة
    HazardousWasteImage = 3,        // إيصال سداد رسوم النقايات الخطرة
    ExteriorImage = 4,              // صورة العيادة من الخارج
    InteriorImage = 5               // صورة العيادة من الداخل
}

public enum RemoteConsultationStatus
{
    Draft = 0,      // مسودة
    Pending = 1,    // قيد المراجعة
    Approved = 2,   // تمت الموافقة
    Rejected = 3,   // مرفوض
    Cancelled = 4   // ملغي
}

// ── Consultation booking (parent side — استشارات طبية) ──

public enum BookingServiceType
{
    Clinic = 1,             // كشف داخل العيادة
    RemoteConsultation = 2  // جلسة اون لاين (الكشف عن بعد)
}

public enum BookingStatus
{
    PendingPayment = 0, // انتظار رفع إيصال الدفع
    PendingReview = 1,  // جاري مراجعة الحجز (تم رفع الإيصال)
    Confirmed = 2,      // تم تأكيد الحجز - انتظار موعد الجلسة
    Rejected = 3,       // مرفوض (رُفض الدفع)
    Cancelled = 4,      // ملغي
    Completed = 5       // انتهت الجلسة (المرحلة الثانية)
}

public enum PaymentMethod
{
    VodafoneCash = 1, // فودافون كاش
    InstaPay = 2      // انستا باي
}

public enum PaymentStatus
{
    Pending = 0,  // قيد المراجعة
    Approved = 1, // تم القبول
    Rejected = 2  // مرفوض
}
