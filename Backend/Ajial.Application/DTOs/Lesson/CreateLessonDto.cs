namespace Ajial.Application.DTOs.Lesson;

public class CreateLessonDto
{
    public Guid CategoryId { get; set; }
    public string TitleAr { get; set; } = string.Empty;
    public string ContentAr { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string? VideoUrl { get; set; }
    public bool IsActive { get; set; } = false;
    public List<CreateLessonQuestionDto> Questions { get; set; } = new();
}

public class CreateLessonQuestionDto
{
    public string QuestionText { get; set; } = string.Empty;
    public int StarsReward { get; set; }
    public List<CreateLessonQuestionOptionDto> Options { get; set; } = new();
}

public class CreateLessonQuestionOptionDto
{
    public string OptionText { get; set; } = string.Empty;
    public bool IsCorrect { get; set; }
}
