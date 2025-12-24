namespace Ajial.Application.DTOs.Parent;

/// <summary>
/// Parent profile data for profile page
/// </summary>
public class GetParentProfileResponseDto
{
    /// <summary>
    /// Profile image URL (nullable - default avatar if null)
    /// </summary>
    public string? ProfileImageUrl { get; set; }

    /// <summary>
    /// Parent's full name
    /// </summary>
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// Unique username
    /// </summary>
    public string Username { get; set; } = string.Empty;

    /// <summary>
    /// Number of children registered under this parent
    /// </summary>
    public int NumberOfChildren { get; set; }

    /// <summary>
    /// Parent's email address
    /// </summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// City name in English
    /// </summary>
    public string CityName { get; set; } = string.Empty;

    /// <summary>
    /// City name in Arabic
    /// </summary>
    public string CityNameAr { get; set; } = string.Empty;

    /// <summary>
    /// Parent's date of birth
    /// </summary>
    public DateTime DateOfBirth { get; set; }

    /// <summary>
    /// Parent's gender (for display)
    /// </summary>
    public string Gender { get; set; } = string.Empty;

    /// <summary>
    /// Parent role code (1=Father, 2=Mother, 3=Educator)
    /// كود دور ولي الأمر (1=أب، 2=أم، 3=مربي)
    /// </summary>
    public int RoleCode { get; set; }

    /// <summary>
    /// Parent role display name in Arabic
    /// اسم دور ولي الأمر بالعربية
    /// </summary>
    public string Role { get; set; } = string.Empty;

    /// <summary>
    /// Parent ID
    /// </summary>
    public Guid ParentId { get; set; }

    /// <summary>
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// Whether email is verified
    /// حالة التحقق من البريد الإلكتروني
    /// </summary>
    public bool IsEmailVerified { get; set; }

    /// <summary>
    /// Email verification status text (Verified/Not Verified)
    /// نص حالة التحقق (مؤكد / غير مؤكد)
    /// </summary>
    public string EmailVerificationStatus { get; set; } = string.Empty;

    // ✅ NEW: List of children
    /// <summary>
    /// List of children with their basic info (for profile page display and future edit)
    /// </summary>
    public List<ChildBasicInfoDto> Children { get; set; } = new List<ChildBasicInfoDto>();
}

/// <summary>
/// Basic child information for parent profile page
/// </summary>
public class ChildBasicInfoDto
{
    /// <summary>
    /// Child unique ID
    /// </summary>
    public Guid ChildId { get; set; }

    /// <summary>
    /// Child's full name
    /// </summary>
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// Child's profile image URL (nullable - default avatar if null)
    /// </summary>
    public string? ProfileImageUrl { get; set; }

    /// <summary>
    /// Child's age
    /// </summary>
    public int Age { get; set; }

    /// <summary>
    /// Child's gender
    /// </summary>
    public string Gender { get; set; } = string.Empty;

    /// <summary>
    /// Whether child has login account (ages 4-13)
    /// </summary>
    public bool HasAccount { get; set; }

    /// <summary>
    /// Child login ID (nullable if no account)
    /// </summary>
    public string? ChildLoginId { get; set; }

    /// <summary>
    /// Whether child account is active
    /// </summary>
    public bool IsActive { get; set; }
}