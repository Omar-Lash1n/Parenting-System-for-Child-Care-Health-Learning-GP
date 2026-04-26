namespace Ajial.Application.DTOs.Prize;

public class PrizeTaskDto
{
    public Guid TaskId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? TaskImageUrl { get; set; }
    public int Stars { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }
}
