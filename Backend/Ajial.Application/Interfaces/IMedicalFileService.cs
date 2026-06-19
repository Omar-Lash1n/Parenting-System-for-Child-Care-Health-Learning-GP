using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.MedicalFile;

namespace Ajial.Application.Interfaces;

/// <summary>
/// خدمة الملف الطبي الموحد للطفل (السجل الطبي) — تجميع البيانات، توليد الـ PDF، رفعه إلى التخزين.
/// </summary>
public interface IMedicalFileService
{
    /// <summary>
    /// يولّد الملف الطبي للطفل (مع التحقق من ملكية ولي الأمر) ويعيد رابط الـ PDF.
    /// </summary>
    Task<ApiResponse<MedicalFileResponse>> GenerateChildMedicalFileAsync(Guid childId, Guid parentUserId);

    /// <summary>
    /// يولّد الملف الطبي ويعيد رابطه فقط (لمشاركته مع الطبيب عند الحجز). يعيد null عند الفشل.
    /// لا يرمي استثناءات — مخصّص للاستدعاء ضمن تدفق الحجز.
    /// </summary>
    Task<string?> TryGenerateShareableUrlAsync(Guid childId, Guid parentId);

    /// <summary>
    /// يعيد توليد الملف الطبي للطفل ويرفعه (يتضمن أحدث التشخيصات والروشتات) ويعيد الرابط الجديد.
    /// يُستدعى بعد أن يضيف الطبيب/يعدّل/يحذف تشخيصاً أو دواءً. يعيد null عند الفشل دون رمي استثناء.
    /// </summary>
    Task<string?> RegenerateForChildAsync(Guid childId);
}
