namespace Ajial.Application.DTOs.Lesson;

public class UpdateLessonCategoryDto
{
    public string NameAr { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public int OrderIndex { get; set; }
    public bool IsActive { get; set; }
}
