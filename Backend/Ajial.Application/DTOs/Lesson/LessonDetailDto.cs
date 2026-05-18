namespace Ajial.Application.DTOs.Lesson;

public class LessonDetailDto
{
    public Guid Id { get; set; }
    public string TitleAr { get; set; } = string.Empty;
    public string ContentAr { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string? VideoUrl { get; set; }
    public Guid CategoryId { get; set; }
    public string CategoryNameAr { get; set; } = string.Empty;
    public int TotalStarsReward { get; set; }
    public int QuestionsCount { get; set; }
    public bool IsRead { get; set; }
    public bool IsQuizCompleted { get; set; }
    public int StarsEarned { get; set; }
}
