namespace Ajial.Application.DTOs.Ranking;

public class AdminCurrentRankingDto
{
    public int TotalParents { get; set; }
    public DateTime GeneratedAt { get; set; }
    public List<AdminCurrentRankingEntryDto> Entries { get; set; } = new();
}
