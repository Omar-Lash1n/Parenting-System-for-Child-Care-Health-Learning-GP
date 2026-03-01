namespace Ajial.Application.DTOs.Vaccination;

/// <summary>
/// استجابة تقديم استبيان التطعيمات - Submit vaccination survey response
/// </summary>
public class SubmitVaccinationSurveyResponseDto
{
    public Guid ChildId { get; set; }
    public int TotalMilestones { get; set; }
    public int TakenCount { get; set; }
    public string Message { get; set; } = string.Empty;
}
