using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.TaskCategory;

public class UpdateCategoryRequestDto
{
    [Required(ErrorMessage = "اسم التصنيف مطلوب")]
    [StringLength(100, MinimumLength = 1, ErrorMessage = "اسم التصنيف يجب أن يكون بين 1 و 100 حرف")]
    public string Name { get; set; } = string.Empty;
}
