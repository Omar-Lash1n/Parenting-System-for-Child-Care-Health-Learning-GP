namespace Ajial.Domain.Entities;

public class DailyQuestionAnswer
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DailyQuestionId { get; set; }
    public DailyQuestion DailyQuestion { get; set; } = null!;
    public Guid ParentId { get; set; }
    public Parent Parent { get; set; } = null!;
    public Guid SelectedOptionId { get; set; }
    public DailyQuestionOption SelectedOption { get; set; } = null!;
    public bool IsCorrect { get; set; }
    public int StarsEarned { get; set; }
    public DateTime AnsweredAt { get; set; } = DateTime.UtcNow;
}
