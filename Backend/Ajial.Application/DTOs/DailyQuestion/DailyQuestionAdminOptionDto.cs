namespace Ajial.Application.DTOs.DailyQuestion;

public class DailyQuestionAdminOptionDto
{
    public Guid Id { get; set; }
    public string OptionText { get; set; } = string.Empty;
    public bool IsCorrect { get; set; }
    public int OrderIndex { get; set; }
}
