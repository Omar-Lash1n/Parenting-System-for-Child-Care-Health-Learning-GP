namespace Ajial.Application.DTOs.Lesson;

public class LessonAdminDetailDto
{
    public Guid Id { get; set; }
    public Guid CategoryId { get; set; }
    public string CategoryNameAr { get; set; } = string.Empty;
    public string TitleAr { get; set; } = string.Empty;
    public string ContentAr { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string? VideoUrl { get; set; }
    public bool IsActive { get; set; }
    public int TotalStarsReward { get; set; }
    public int TotalReads { get; set; }
    public int TotalCompletions { get; set; }
    public List<LessonAdminQuestionDto> Questions { get; set; } = new();
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class LessonAdminQuestionDto
{
    public Guid Id { get; set; }
    public string QuestionText { get; set; } = string.Empty;
    public int StarsReward { get; set; }
    public int OrderIndex { get; set; }
    public List<LessonAdminOptionDto> Options { get; set; } = new();
}

public class LessonAdminOptionDto
{
    public Guid Id { get; set; }
    public string OptionText { get; set; } = string.Empty;
    public bool IsCorrect { get; set; }
    public int OrderIndex { get; set; }
}
