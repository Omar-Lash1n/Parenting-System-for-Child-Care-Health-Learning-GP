namespace Ajial.Application.DTOs.Prize;

public class ChildPrizeSummaryDto
{
    public Guid ChildId { get; set; }
    public string ChildFullName { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public int TotalStars { get; set; }
    public int ActivePrizesCount { get; set; }
    public int ReadyPrizesCount { get; set; }
    public int DeliveredPrizesCount { get; set; }
}
