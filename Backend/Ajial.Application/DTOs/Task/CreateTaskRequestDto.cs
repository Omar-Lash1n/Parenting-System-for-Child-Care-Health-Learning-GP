using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.Task;

public class CreateTaskRequestDto
{
    [Required(ErrorMessage = "عنوان المهمة مطلوب")]
    [StringLength(200, MinimumLength = 1, ErrorMessage = "عنوان المهمة يجب أن يكون بين 1 و 200 حرف")]
    public string Title { get; set; } = string.Empty;

    public Guid? CategoryId { get; set; }

    public string? Color { get; set; }

    /// <summary>
    /// If null → DueDate defaults to today; IsPushSent = true (no notification).
    /// If provided → stored as-is; IsPushSent = false (background worker fires notification).
    /// </summary>
    public DateTime? DueDate { get; set; }

    public bool IncludeParent { get; set; } = false;

    public List<Guid> ChildIds { get; set; } = new();
}
