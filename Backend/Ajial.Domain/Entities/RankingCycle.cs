namespace Ajial.Domain.Entities;

public class RankingCycle
{
    public Guid Id { get; set; }
    public string SeasonName { get; set; } = string.Empty;
    public DateTime PublishedAt { get; set; }
    public DateTime NextPublishAt { get; set; }
    public ICollection<RankingEntry> Entries { get; set; } = new List<RankingEntry>();
}
