namespace Ajial.Application.DTOs.Parent;

public class ParentAnalyticsDto
{
    // User Information
    public Guid UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public DateTime UserCreatedAt { get; set; }
    public DateTime? UserUpdatedAt { get; set; }  // ✅ Changed to nullable


    // Parent Information
    public Guid ParentId { get; set; }
    public DateTime DateOfBirth { get; set; }
    public int Age { get; set; }
    public string Gender { get; set; } = string.Empty;  // "Male" or "Female"
    public int GenderCode { get; set; }  // 1 = Male, 2 = Female

    // City Information
    public int CityId { get; set; }
    public string CityName { get; set; } = string.Empty;
    public string CityNameAr { get; set; } = string.Empty;
    public bool CityIsActive { get; set; }

    // Calculated Fields
    public int AccountAgeInDays { get; set; }
    public string AgeGroup { get; set; } = string.Empty;  // "18-25", "26-35", "36-45", "46+"
    public string Region { get; set; } = string.Empty;  // Based on city
}