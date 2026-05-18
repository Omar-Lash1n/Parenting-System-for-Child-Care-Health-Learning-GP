namespace Ajial.Application.DTOs.Lesson;

public class CreateLessonCategoryDto
{
    public string NameAr { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public int OrderIndex { get; set; } = 0;
}
