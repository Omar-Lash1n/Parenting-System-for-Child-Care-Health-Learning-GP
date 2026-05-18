namespace Ajial.Domain.Entities;

public class LessonProgress
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ParentId { get; set; }
    public Parent Parent { get; set; } = null!;
    public Guid LessonId { get; set; }
    public Lesson Lesson { get; set; } = null!;
    public bool IsRead { get; set; } = false;
    public DateTime? ReadAt { get; set; }
    public bool IsQuizCompleted { get; set; } = false;
    public DateTime? QuizCompletedAt { get; set; }
    public int TotalStarsEarned { get; set; } = 0;
}
