namespace Ajial.Application.DTOs.DailyQuestion;

public class DailyQuestionAnswerResultDto
{
    public bool IsCorrect { get; set; }
    public int StarsEarned { get; set; }
    public Guid CorrectOptionId { get; set; }
    public int NewStarsBalance { get; set; }
}
