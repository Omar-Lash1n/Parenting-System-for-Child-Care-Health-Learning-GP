using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.DailyQuestion;

public class SubmitDailyQuestionAnswerDto
{
    [Required(ErrorMessage = "لم يتم اختيار إجابة")]
    public Guid SelectedOptionId { get; set; }
}
