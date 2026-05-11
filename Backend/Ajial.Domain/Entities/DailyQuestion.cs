namespace Ajial.Domain.Entities;

public class DailyQuestion
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string QuestionText { get; set; } = string.Empty;
    public int StarsReward { get; set; }
    public bool IsActive { get; set; } = false;
    public Guid CreatedByAdminId { get; set; }
    public User CreatedByAdmin { get; set; } = null!;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public ICollection<DailyQuestionOption> Options { get; set; } = new List<DailyQuestionOption>();
    public ICollection<DailyQuestionAnswer> Answers { get; set; } = new List<DailyQuestionAnswer>();
}
