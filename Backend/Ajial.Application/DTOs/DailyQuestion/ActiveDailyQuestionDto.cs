namespace Ajial.Application.DTOs.DailyQuestion;

public class ActiveDailyQuestionDto
{
    public Guid Id { get; set; }
    public string QuestionText { get; set; } = string.Empty;
    public int StarsReward { get; set; }
    public List<ParentQuestionOptionDto> Options { get; set; } = new();
    public bool HasAnswered { get; set; }
    public PreviousAnswerDto? PreviousAnswer { get; set; }
}
