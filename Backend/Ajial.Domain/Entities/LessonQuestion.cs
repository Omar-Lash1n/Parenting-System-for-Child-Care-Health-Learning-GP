namespace Ajial.Domain.Entities;

public class LessonQuestion
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid LessonId { get; set; }
    public Lesson Lesson { get; set; } = null!;
    public string QuestionText { get; set; } = string.Empty;
    public int StarsReward { get; set; }
    public int OrderIndex { get; set; }

    public ICollection<LessonQuestionOption> Options { get; set; } = new List<LessonQuestionOption>();
    public ICollection<LessonQuestionAnswer> Answers { get; set; } = new List<LessonQuestionAnswer>();
}
