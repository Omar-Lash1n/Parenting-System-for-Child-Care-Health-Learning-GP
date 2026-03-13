using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.Vaccination;

/// <summary>
/// طلب تبديل حالة التطعيم - Toggle a vaccination's taken status
/// </summary>
public class ToggleVaccinationRequestDto
{
    [Required(ErrorMessage = "معرّف الطفل مطلوب")]
    public Guid ChildId { get; set; }

    [Required(ErrorMessage = "معرّف التطعيم مطلوب")]
    public int MilestoneId { get; set; }

    /// <summary>
    /// الحالة المطلوبة: true = تم أخذه, false = لم يتم أخذه
    /// </summary>
    public bool IsTaken { get; set; }
}

/// <summary>
/// استجابة تبديل حالة التطعيم
/// </summary>
public class ToggleVaccinationResponseDto
{
    public Guid ChildId { get; set; }
    public int MilestoneId { get; set; }

    /// <summary>
    /// الحالة المؤكدة بعد التبديل
    /// </summary>
    public bool IsTaken { get; set; }

    /// <summary>
    /// اسم التطعيم بالعربي (للتأكيد في واجهة المستخدم)
    /// </summary>
    public string MilestoneNameAr { get; set; } = string.Empty;

    /// <summary>
    /// رسالة النجاح
    /// </summary>
    public string Message { get; set; } = string.Empty;
}
