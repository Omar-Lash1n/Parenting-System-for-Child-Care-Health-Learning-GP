namespace Ajial.Application.DTOs.Ranking;

public class PublishedRankingDto
{
    public Guid CycleId { get; set; }
    public string SeasonName { get; set; } = string.Empty;
    public DateTime PublishedAt { get; set; }
    public DateTime NextPublishAt { get; set; }
    public List<RankingEntryDto> Entries { get; set; } = new();
}
