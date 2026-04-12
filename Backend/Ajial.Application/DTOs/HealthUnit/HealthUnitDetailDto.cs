namespace Ajial.Application.DTOs.HealthUnit;

/// <summary>
/// Detailed DTO for a single health unit — extends list item with extra fields
/// </summary>
public class HealthUnitDetailDto : HealthUnitListItemDto
{
    /// <summary>Google Maps directions deep-link</summary>
    public string? GoogleMapsUrl { get; set; }

    /// <summary>ملاحظات — working hours, extra info</summary>
    public string? Notes { get; set; }

    /// <summary>هل تم التحقق من البيانات؟</summary>
    public bool IsVerified { get; set; }
}
