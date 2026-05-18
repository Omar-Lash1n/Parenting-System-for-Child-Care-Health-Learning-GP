namespace Ajial.Application.DTOs.Lesson;

public class GetLessonsQueryDto
{
    public Guid? CategoryId { get; set; }
    public string? Search { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
