namespace Ajial.Application.DTOs.Prize;

public class PrizeCardDto
{
    public Guid PrizeId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public int RequiredStars { get; set; }
    public int CurrentStars { get; set; }
    public int RemainingStars { get; set; }
    public int CompletedTasksCount { get; set; }
    public int TotalRequiredTasks { get; set; }
    public string Status { get; set; } = string.Empty;
    public bool CanDeliver { get; set; }
}
