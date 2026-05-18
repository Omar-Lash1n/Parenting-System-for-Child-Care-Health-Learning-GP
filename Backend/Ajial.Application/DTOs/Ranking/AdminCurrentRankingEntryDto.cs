namespace Ajial.Application.DTOs.Ranking;

public class AdminCurrentRankingEntryDto
{
    public Guid ParentId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public int ChildrenCount { get; set; }
    public int Stars { get; set; }
    public int Rank { get; set; }
    public string? ProjectedBadge { get; set; }
}
