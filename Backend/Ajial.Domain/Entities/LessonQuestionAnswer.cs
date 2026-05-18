namespace Ajial.Domain.Entities;

public class LessonQuestionAnswer
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ParentId { get; set; }
    public Parent Parent { get; set; } = null!;
    public Guid LessonQuestionId { get; set; }
    public LessonQuestion LessonQuestion { get; set; } = null!;
    public Guid SelectedOptionId { get; set; }
    public LessonQuestionOption SelectedOption { get; set; } = null!;
    public bool IsCorrect { get; set; }
    public int StarsEarned { get; set; }
    public DateTime AnsweredAt { get; set; } = DateTime.UtcNow;
}
