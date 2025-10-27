using Ajial.Domain.Entities;

namespace Ajial.Application.DTOs.Auth;

public class LoginResponseDto
{
    public Guid UserId { get; set; }
    public Guid ParentId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public ParentGender Gender { get; set; }
    public string CityName { get; set; } = string.Empty;
    public string CityNameAr { get; set; } = string.Empty;
    public DateTime DateOfBirth { get; set; }
    public string Message { get; set; } = "تم تسجيل الدخول بنجاح";
    public DateTime LoginAt { get; set; } = DateTime.UtcNow;
}