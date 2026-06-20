using Ajial.Domain.Entities;

namespace Ajial.Application.Helpers;

/// <summary>مفاتيح وتسميات عربية لحالات الحجز والدفع وأنواع الخدمة — مشتركة بين خدمات الاستشارات.</summary>
public static class ConsultationLabels
{
    public static string BookingStatusKey(BookingStatus s) => s switch
    {
        BookingStatus.PendingPayment => "pending_payment",
        BookingStatus.PendingReview => "pending_review",
        BookingStatus.Confirmed => "confirmed",
        BookingStatus.Rejected => "rejected",
        BookingStatus.Cancelled => "cancelled",
        BookingStatus.Completed => "completed",
        _ => "unknown"
    };

    public static string BookingStatusAr(BookingStatus s) => s switch
    {
        BookingStatus.PendingPayment => "انتظار الدفع",
        BookingStatus.PendingReview => "جاري مراجعة الحجز",
        BookingStatus.Confirmed => "انتظار موعد الجلسة",
        BookingStatus.Rejected => "تم رفض الحجز",
        BookingStatus.Cancelled => "ملغي",
        BookingStatus.Completed => "جلسة مكتملة",
        _ => "غير معروف"
    };

    public static string PaymentStatusKey(PaymentStatus s) => s switch
    {
        PaymentStatus.Pending => "pending",
        PaymentStatus.Approved => "approved",
        PaymentStatus.Rejected => "rejected",
        _ => "unknown"
    };

    public static string PaymentStatusAr(PaymentStatus s) => s switch
    {
        PaymentStatus.Pending => "جاري المراجعة",
        PaymentStatus.Approved => "تم القبول",
        PaymentStatus.Rejected => "مرفوض",
        _ => "غير معروف"
    };

    public static string ServiceTypeKey(BookingServiceType t) => t switch
    {
        BookingServiceType.Clinic => "clinic",
        BookingServiceType.RemoteConsultation => "remote",
        _ => "unknown"
    };

    public static string ServiceTypeAr(BookingServiceType t) => t switch
    {
        BookingServiceType.Clinic => "كشف داخل العيادة",
        BookingServiceType.RemoteConsultation => "جلسة اون لاين",
        _ => "غير معروف"
    };

    public static string PaymentMethodKey(PaymentMethod m) => m switch
    {
        PaymentMethod.VodafoneCash => "vodafone_cash",
        PaymentMethod.InstaPay => "instapay",
        _ => "unknown"
    };

    public static string PaymentMethodAr(PaymentMethod m) => m switch
    {
        PaymentMethod.VodafoneCash => "فودافون كاش",
        PaymentMethod.InstaPay => "انستا باي",
        _ => "غير معروف"
    };

    // ── الإبلاغ عن مشكلة ──
    public static string ProblemCategoryKey(ProblemReportCategory c) => c switch
    {
        ProblemReportCategory.UnprofessionalConduct => "unprofessional_conduct",
        ProblemReportCategory.IncorrectDoctorInfo => "incorrect_doctor_info",
        ProblemReportCategory.DoctorNoShow => "doctor_no_show",
        ProblemReportCategory.Other => "other",
        _ => "unknown"
    };

    public static string ProblemCategoryAr(ProblemReportCategory c) => c switch
    {
        ProblemReportCategory.UnprofessionalConduct => "سلوك غير مهني أو غير لائق",
        ProblemReportCategory.IncorrectDoctorInfo => "معلومات الطبيب/العيادة غير صحيحة",
        ProblemReportCategory.DoctorNoShow => "عدم حضور الطبيب في موعد الجلسة",
        ProblemReportCategory.Other => "سبب اخر",
        _ => "غير معروف"
    };

    public static string ProblemStatusKey(ProblemReportStatus s) => s switch
    {
        ProblemReportStatus.New => "new",
        ProblemReportStatus.UnderReview => "under_review",
        ProblemReportStatus.Resolved => "resolved",
        _ => "unknown"
    };

    public static string ProblemStatusAr(ProblemReportStatus s) => s switch
    {
        ProblemReportStatus.New => "جديد",
        ProblemReportStatus.UnderReview => "قيد المراجعة",
        ProblemReportStatus.Resolved => "تم الحل",
        _ => "غير معروف"
    };

    // نسبة رسوم إلغاء الحجز (تُخصم من المبلغ المدفوع عند إلغاء ولي الأمر للحجز المؤكد)
    public const int CancellationFeePercent = 10;

    // مفاتيح إعدادات الدفع
    public const string VodafoneCashKey = "VodafoneCashNumber";
    public const string InstaPayKey = "InstaPayNumber";
    public const string DefaultWalletNumber = "01146486517";
}
