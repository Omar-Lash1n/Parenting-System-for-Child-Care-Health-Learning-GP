namespace Ajial.Application.DTOs.Analytics;

/// <summary>
/// Flat structure for Power BI - All child data with parent info
/// </summary>
public class ChildAnalyticsDto
{
    // Child Information
    public Guid ChildId { get; set; }
    public string ChildFullName { get; set; } = string.Empty;
    public DateTime ChildBirthDate { get; set; }
    public int ChildAge { get; set; }
    public string ChildGender { get; set; } = string.Empty;
    public string? ChildProfileImageUrl { get; set; }
    public string? ChildLoginId { get; set; }
    public bool ChildHasAccount { get; set; }
    public bool ChildIsActive { get; set; }
    public DateTime ChildCreatedAt { get; set; }
    public DateTime ChildUpdatedAt { get; set; }
    
    // Parent Information
    public Guid ParentId { get; set; }
    public Guid ParentUserId { get; set; }
    public string ParentFullName { get; set; } = string.Empty;
    public string ParentUsername { get; set; } = string.Empty;
    public string ParentEmail { get; set; } = string.Empty;
    public string ParentGender { get; set; } = string.Empty;
    public DateTime ParentDateOfBirth { get; set; }
    public int ParentAge { get; set; }
    public bool ParentIsActive { get; set; }
    public DateTime ParentCreatedAt { get; set; }
    
    // City Information
    public int CityId { get; set; }
    public string CityName { get; set; } = string.Empty;
    public string CityNameAr { get; set; } = string.Empty;
    
    // Calculated Fields
    public string AgeGroup { get; set; } = string.Empty; // "0-3", "4-7", "8-13", "14+"
    public int DaysSinceRegistration { get; set; }
    public string RegistrationMonth { get; set; } = string.Empty; // "2025-11"
    public string RegistrationYear { get; set; } = string.Empty; // "2025"
}