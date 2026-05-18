namespace Ajial.Application.DTOs.Lesson;

public class MarkLessonReadResponseDto
{
    public bool IsRead { get; set; }
    public List<LessonQuizQuestionDto> Questions { get; set; } = new();
}

public class LessonQuizQuestionDto
{
    public Guid Id { get; set; }
    public string QuestionText { get; set; } = string.Empty;
    public int StarsReward { get; set; }
    public int OrderIndex { get; set; }
    public List<LessonQuizOptionDto> Options { get; set; } = new();
    public bool HasAnswered { get; set; }
    public LessonPreviousAnswerDto? PreviousAnswer { get; set; }
}

public class LessonQuizOptionDto
{
    public Guid Id { get; set; }
    public string OptionText { get; set; } = string.Empty;
    public int OrderIndex { get; set; }
}

public class LessonPreviousAnswerDto
{
    public Guid SelectedOptionId { get; set; }
    public bool IsCorrect { get; set; }
    public int StarsEarned { get; set; }
    public Guid CorrectOptionId { get; set; }
}
