namespace Ajial.Application.DTOs.Lesson;

public class UpdateLessonDto
{
    public Guid CategoryId { get; set; }
    public string TitleAr { get; set; } = string.Empty;
    public string ContentAr { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string? VideoUrl { get; set; }
    public List<CreateLessonQuestionDto> Questions { get; set; } = new();
}
