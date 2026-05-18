namespace Ajial.Application.DTOs.Lesson;

public class LessonAdminListDto
{
    public Guid Id { get; set; }
    public string TitleAr { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string CategoryNameAr { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public int QuestionsCount { get; set; }
    public int TotalStarsReward { get; set; }
    public int TotalReads { get; set; }
    public int TotalCompletions { get; set; }
    public DateTime CreatedAt { get; set; }
}
