namespace Ajial.Application.DTOs.Ranking;

public class AdminPublishedRankingDto
{
    public Guid CycleId { get; set; }
    public string SeasonName { get; set; } = string.Empty;
    public DateTime PublishedAt { get; set; }
    public DateTime NextPublishAt { get; set; }
    public int TotalParents { get; set; }
    public List<RankingEntryDto> TopThree { get; set; } = new();
}
