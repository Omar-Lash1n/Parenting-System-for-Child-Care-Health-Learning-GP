namespace Ajial.Application.DTOs.Analytics;

/// <summary>
/// Flat structure for Power BI - One row per parent-child relationship
/// </summary>
public class ParentChildrenFlatDto
{
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
    
    // Parent Statistics
    public int TotalChildren { get; set; }
    public int ActiveChildren { get; set; }
    public int ChildrenWithAccounts { get; set; }
    
    // Child Information (One child per row)
    public Guid? ChildId { get; set; }
    public string? ChildFullName { get; set; }
    public DateTime? ChildBirthDate { get; set; }
    public int? ChildAge { get; set; }
    public string? ChildGender { get; set; }
    public string? ChildProfileImageUrl { get; set; }
    public string? ChildLoginId { get; set; }
    public bool? ChildHasAccount { get; set; }
    public bool? ChildIsActive { get; set; }
    public DateTime? ChildCreatedAt { get; set; }
    public DateTime? ChildUpdatedAt { get; set; }
    
    // Child Calculated Fields
    public string? ChildAgeGroup { get; set; }
    public int? ChildDaysSinceRegistration { get; set; }
}