namespace Ajial.Application.DTOs.Parent;

/// <summary>
/// Response after updating parent profile
/// </summary>
public class UpdateParentProfileResponseDto
{
    /// <summary>
    /// Parent ID
    /// </summary>
    public Guid ParentId { get; set; }
    
    /// <summary>
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// Updated full name
    /// </summary>
    public string FullName { get; set; } = string.Empty;
    
    /// <summary>
    /// Updated username
    /// </summary>
    public string Username { get; set; } = string.Empty;
    
    /// <summary>
    /// Updated email
    /// </summary>
    public string Email { get; set; } = string. Empty;
    
    /// <summary>
    /// City name in English
    /// </summary>
    public string CityName { get; set; } = string.Empty;
    
    /// <summary>
    /// City name in Arabic
    /// </summary>
    public string CityNameAr { get; set; } = string.Empty;
    
    /// <summary>
    /// Updated date of birth
    /// </summary>
    public DateTime DateOfBirth { get; set; }
    
    /// <summary>
    /// Updated role (Father/Mother/Educator)
    /// </summary>
    public string Role { get; set; } = string.Empty;
    
    /// <summary>
    /// When the profile was updated
    /// </summary>
    public DateTime UpdatedAt { get; set; }
    
    /// <summary>
    /// List of fields that were updated
    /// </summary>
    public List<string> FieldsUpdated { get; set; } = new List<string>();
    
    /// <summary>
    /// Success message
    /// </summary>
    public string Message { get; set; } = string.Empty;
}