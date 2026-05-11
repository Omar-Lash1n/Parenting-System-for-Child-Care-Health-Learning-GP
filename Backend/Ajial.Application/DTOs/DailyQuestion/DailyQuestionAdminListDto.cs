namespace Ajial.Application.DTOs.DailyQuestion;

public class DailyQuestionAdminListDto
{
    public Guid Id { get; set; }
    public string QuestionText { get; set; } = string.Empty;
    public int StarsReward { get; set; }
    public bool IsActive { get; set; }
    public int TotalAnswers { get; set; }
    public int CorrectAnswers { get; set; }
    public DateTime CreatedAt { get; set; }
}
