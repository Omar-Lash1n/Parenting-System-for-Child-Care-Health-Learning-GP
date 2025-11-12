namespace Ajial.Application.DTOs.Auth;

public class ResetPasswordResponseDto
{
    public string Message { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public DateTime ResetAt { get; set; }
}