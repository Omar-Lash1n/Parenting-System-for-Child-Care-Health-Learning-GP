namespace Ajial.Domain.Entities;

public class DailyQuestionOption
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DailyQuestionId { get; set; }
    public DailyQuestion DailyQuestion { get; set; } = null!;
    public string OptionText { get; set; } = string.Empty;
    public bool IsCorrect { get; set; } = false;
    public int OrderIndex { get; set; }
}
