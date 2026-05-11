using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.DailyQuestion;

public class DailyQuestionOptionDto
{
    [Required(ErrorMessage = "نص الخيار مطلوب")]
    [StringLength(300, MinimumLength = 1, ErrorMessage = "نص الخيار يجب أن يكون بين 1 و 300 حرف")]
    public string OptionText { get; set; } = string.Empty;

    public bool IsCorrect { get; set; }
}
