using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.DailyQuestion;

public class CreateDailyQuestionDto
{
    [Required(ErrorMessage = "نص السؤال مطلوب")]
    [StringLength(500, MinimumLength = 1, ErrorMessage = "نص السؤال يجب أن يكون بين 1 و 500 حرف")]
    public string QuestionText { get; set; } = string.Empty;

    [Range(1, int.MaxValue, ErrorMessage = "عدد النجوم يجب أن يكون أكبر من صفر")]
    public int StarsReward { get; set; }

    public bool IsActive { get; set; } = false;

    [Required(ErrorMessage = "يجب إضافة خيارين على الأقل")]
    [MinLength(2, ErrorMessage = "يجب إضافة خيارين على الأقل")]
    public List<DailyQuestionOptionDto> Options { get; set; } = new();
}
