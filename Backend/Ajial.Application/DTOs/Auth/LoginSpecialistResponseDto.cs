namespace Ajial.Application.DTOs.Auth;

public class LoginSpecialistResponseDto
{
    public Guid UserId { get; set; }
    public Guid SpecialistId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Specialization { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string PersonalPhotoUrl { get; set; } = string.Empty;
    public string Message { get; set; } = "تم تسجيل الدخول بنجاح";
    public DateTime LoginAt { get; set; } = DateTime.UtcNow;
    public string Token { get; set; } = string.Empty;
}
