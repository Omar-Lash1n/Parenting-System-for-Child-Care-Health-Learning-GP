namespace Ajial.Application.DTOs.DailyQuestion;

public class ParentQuestionOptionDto
{
    public Guid Id { get; set; }
    public string OptionText { get; set; } = string.Empty;
    public int OrderIndex { get; set; }
}
