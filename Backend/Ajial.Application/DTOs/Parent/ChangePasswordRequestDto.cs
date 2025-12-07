namespace Ajial.Application.DTOs.Parent;

/// <summary>
/// Request to change parent's password from profile page
/// </summary>
public class ChangePasswordRequestDto
{
    /// <summary>
    /// Current password (for verification)
    /// </summary>
    public string CurrentPassword { get; set; } = string.Empty;
    
    /// <summary>
    /// New password (must meet strength requirements)
    /// </summary>
    public string NewPassword { get; set; } = string. Empty;
    
    /// <summary>
    /// Confirm new password (must match NewPassword)
    /// </summary>
    public string ConfirmNewPassword { get; set; } = string.Empty;
}