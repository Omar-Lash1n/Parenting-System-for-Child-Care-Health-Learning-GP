namespace Ajial.Domain.Entities;

public class LessonQuestionOption
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid LessonQuestionId { get; set; }
    public LessonQuestion LessonQuestion { get; set; } = null!;
    public string OptionText { get; set; } = string.Empty;
    public bool IsCorrect { get; set; }
    public int OrderIndex { get; set; }
}
