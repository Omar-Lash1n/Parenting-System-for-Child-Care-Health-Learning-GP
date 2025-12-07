namespace Ajial.Application.DTOs.Parent;

/// <summary>
/// Request to update parent profile fields (all fields optional for partial updates)
/// </summary>
public class UpdateParentProfileRequestDto
{
    /// <summary>
    /// Parent's full name (optional)
    /// </summary>
    public string?  FullName { get; set; }
    
    /// <summary>
    /// Username (optional, must be unique if changed)
    /// </summary>
    public string? Username { get; set; }
    
    /// <summary>
    /// Email address (optional, must be unique if changed)
    /// </summary>
    public string? Email { get; set; }
    
    /// <summary>
    /// City ID (optional, must exist in Cities table)
    /// </summary>
    public int? CityId { get; set; }
    
    /// <summary>
    /// Date of birth (optional, must be 18+ years old)
    /// </summary>
    public DateTime? DateOfBirth { get; set; }
    
    /// <summary>
    /// Parent role: 1=Father, 2=Mother, 3=Educator (optional)
    /// </summary>
    public int? Role { get; set; }
}