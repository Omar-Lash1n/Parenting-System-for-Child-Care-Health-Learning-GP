namespace Ajial.Application.DTOs.Ranking;

public class ParentBadgeDto
{
    public Guid CycleId { get; set; }
    public string SeasonName { get; set; } = string.Empty;
    public string Badge { get; set; } = string.Empty;
    public int Rank { get; set; }
    public int Stars { get; set; }
    public DateTime AwardedAt { get; set; }
}
