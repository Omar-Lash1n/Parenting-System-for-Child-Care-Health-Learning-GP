using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.Vaccination;

/// <summary>
/// طلب تقديم استبيان التطعيمات - Submit vaccination survey request
/// </summary>
public class SubmitVaccinationSurveyRequestDto
{
    [Required(ErrorMessage = "معرّف الطفل مطلوب")]
    public Guid ChildId { get; set; }

    [Required(ErrorMessage = "يجب تحديد التطعيمات")]
    public List<VaccinationSelectionDto> Selections { get; set; } = new();
}

/// <summary>
/// اختيار تطعيم واحد
/// </summary>
public class VaccinationSelectionDto
{
    public int MilestoneId { get; set; }
    public bool IsTaken { get; set; }
}
