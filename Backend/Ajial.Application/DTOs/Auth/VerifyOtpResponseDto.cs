namespace Ajial.Application.DTOs.Auth;

public class VerifyOtpResponseDto
{
    public bool IsValid { get; set; }
    public string Message { get; set; } = string.Empty;
    public DateTime VerifiedAt { get; set; }
}