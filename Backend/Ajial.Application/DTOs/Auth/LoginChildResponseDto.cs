namespace Ajial.Application.DTOs.Auth;

/// <summary>
/// استجابة تسجيل دخول الطفل
/// </summary>
public class LoginChildResponseDto
{
    public Guid ChildId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public int Age { get; set; }
    public string Gender { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public Guid ParentId { get; set; }
    public string Message { get; set; } = string.Empty;
    public DateTime LoginAt { get; set; }
    
    /// <summary>
    /// JWT Token for child authentication (if needed)
    /// </summary>
    public string? Token { get; set; }
}