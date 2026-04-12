namespace Ajial.Application.DTOs.HealthUnit;

/// <summary>
/// Paginated search response for health units
/// </summary>
public class SearchHealthUnitsResponse
{
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public List<HealthUnitListItemDto> Items { get; set; } = new();
}
