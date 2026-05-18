namespace Ajial.Application.DTOs.Lesson;

public class LessonAnswerResultDto
{
    public bool IsCorrect { get; set; }
    public int StarsEarned { get; set; }
    public Guid CorrectOptionId { get; set; }
    public int NewStarsBalance { get; set; }
    public bool IsQuizCompleted { get; set; }
    public int TotalLessonStarsEarned { get; set; }
}
