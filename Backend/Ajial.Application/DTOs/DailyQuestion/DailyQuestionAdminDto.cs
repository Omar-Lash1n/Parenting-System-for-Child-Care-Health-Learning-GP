namespace Ajial.Application.DTOs.DailyQuestion;

public class DailyQuestionAdminDto
{
    public Guid Id { get; set; }
    public string QuestionText { get; set; } = string.Empty;
    public int StarsReward { get; set; }
    public bool IsActive { get; set; }
    public List<DailyQuestionAdminOptionDto> Options { get; set; } = new();
    public int TotalAnswers { get; set; }
    public int CorrectAnswers { get; set; }
    public DateTime CreatedAt { get; set; }
}
