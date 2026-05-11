namespace Ajial.Application.DTOs.DailyQuestion;

public class PreviousAnswerDto
{
    public Guid SelectedOptionId { get; set; }
    public bool IsCorrect { get; set; }
    public int StarsEarned { get; set; }
    public Guid CorrectOptionId { get; set; }
}
