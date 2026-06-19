using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Consultation;

namespace Ajial.Application.Interfaces;

/// <summary>
/// خدمة الاستشارات الطبية لجانب الطبيب — المرحلة الثالثة: بدء جلسة الكشف اون لاين.
/// (بقية تدفّق الطبيب يُبنى في مراحل لاحقة.)
/// </summary>
public interface IDoctorConsultationService
{
    /// <summary>
    /// يبدأ الطبيب جلسة الكشف اون لاين: يُنشئ رابط Google Meet ويُرجعه.
    /// idempotent — الضغط مرتين يُعيد نفس الرابط دون إنشاء اجتماع جديد.
    /// </summary>
    Task<ApiResponse<StartSessionResponse>> StartSessionAsync(Guid userId, Guid bookingId);
}
