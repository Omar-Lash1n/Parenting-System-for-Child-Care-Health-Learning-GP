namespace Ajial.Application.DTOs.Prize;

public class PrizeDetailDto : PrizeCardDto
{
    public Guid ChildId { get; set; }
    public string ChildFullName { get; set; } = string.Empty;
    public string? ChildProfileImageUrl { get; set; }
    public List<PrizeTaskDto> RequiredTasks { get; set; } = new();
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
}
