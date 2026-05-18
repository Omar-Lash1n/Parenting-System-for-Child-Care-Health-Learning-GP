namespace Ajial.Application.DTOs.Ranking;

public class PagedRankingDto
{
    public Guid CycleId { get; set; }
    public string SeasonName { get; set; } = string.Empty;
    public DateTime PublishedAt { get; set; }
    public DateTime NextPublishAt { get; set; }
    public List<RankingEntryDto> Entries { get; set; } = new();

    public int TotalEntries { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
    public bool HasNextPage { get; set; }
    public bool HasPreviousPage { get; set; }
}
