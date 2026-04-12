namespace Ajial.Application.DTOs.HealthUnit;

/// <summary>
/// Request parameters for searching health units / vaccination places
/// </summary>
public class SearchHealthUnitsRequest
{
    /// <summary>Parent's current latitude (خط العرض)</summary>
    public double? Latitude { get; set; }

    /// <summary>Parent's current longitude (خط الطول)</summary>
    public double? Longitude { get; set; }

    /// <summary>Search keyword — matches Arabic or English name</summary>
    public string? Keyword { get; set; }

    /// <summary>Filter by type: "HealthUnit", "Hospital", "VaccinationCenter", or null for all</summary>
    public string? Type { get; set; }

    /// <summary>Filter by city/governorate ID</summary>
    public int? CityId { get; set; }

    /// <summary>Max search radius in km (default: 50, max: 200)</summary>
    public double RadiusKm { get; set; } = 50;

    /// <summary>Page number (default: 1)</summary>
    public int Page { get; set; } = 1;

    /// <summary>Results per page (default: 20, max: 50)</summary>
    public int PageSize { get; set; } = 20;
}
