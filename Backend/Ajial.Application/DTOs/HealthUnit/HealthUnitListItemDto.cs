namespace Ajial.Application.DTOs.HealthUnit;

/// <summary>
/// DTO for health unit list items in search results
/// </summary>
public class HealthUnitListItemDto
{
    public int Id { get; set; }
    public string NameAr { get; set; } = string.Empty;
    public string NameEn { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public string TypeAr { get; set; } = string.Empty;
    public string AddressAr { get; set; } = string.Empty;
    public string? AddressEn { get; set; }
    public int CityId { get; set; }
    public string CityNameAr { get; set; } = string.Empty;
    public string CityNameEn { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? Phone { get; set; }

    /// <summary>Distance in km from parent's location — null when lat/lng not provided</summary>
    public double? DistanceKm { get; set; }

    public bool IsActive { get; set; }
}
