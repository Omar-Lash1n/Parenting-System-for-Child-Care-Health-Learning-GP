namespace Ajial.Application.DTOs.Ranking;

public class PagedAdminCurrentRankingDto
{
    public int TotalParents { get; set; }
    public DateTime GeneratedAt { get; set; }
    public List<AdminCurrentRankingEntryDto> Entries { get; set; } = new();

    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
    public bool HasNextPage { get; set; }
    public bool HasPreviousPage { get; set; }
}
