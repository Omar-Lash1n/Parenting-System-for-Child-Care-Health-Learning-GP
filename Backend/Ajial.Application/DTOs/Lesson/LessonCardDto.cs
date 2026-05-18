namespace Ajial.Application.DTOs.Lesson;

public class LessonCardDto
{
    public Guid Id { get; set; }
    public string TitleAr { get; set; } = string.Empty;
    public string ContentPreviewAr { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string CategoryNameAr { get; set; } = string.Empty;
    public Guid CategoryId { get; set; }
    public int TotalStarsReward { get; set; }
    public int QuestionsCount { get; set; }
    public bool IsRead { get; set; }
    public bool IsQuizCompleted { get; set; }
    public int StarsEarned { get; set; }
}
