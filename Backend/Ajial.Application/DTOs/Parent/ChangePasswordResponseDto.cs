namespace Ajial.Application.DTOs.Parent;

/// <summary>
/// Response after successfully changing password
/// </summary>
public class ChangePasswordResponseDto
{
    /// <summary>
    /// Success message
    /// </summary>
    public string Message { get; set; } = string.Empty;
    
    /// <summary>
    /// When the password was changed
    /// </summary>
    public DateTime ChangedAt { get; set; }
    
    /// <summary>
    /// User can stay logged in (no need to re-login)
    /// </summary>
    public bool StayLoggedIn { get; set; } = true;
}