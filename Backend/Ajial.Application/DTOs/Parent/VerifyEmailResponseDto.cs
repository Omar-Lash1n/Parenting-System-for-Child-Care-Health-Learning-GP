namespace Ajial.Application.DTOs.Parent;

/// <summary>
/// Response after successfully verifying email
/// الاستجابة بعد التحقق من البريد الإلكتروني بنجاح
/// </summary>
public class VerifyEmailResponseDto
{
    /// <summary>
    /// Success message
    /// رسالة النجاح
    /// </summary>
    public string Message { get; set; } = string.Empty;

    /// <summary>
    /// Email address that was verified
    /// البريد الإلكتروني الذي تم التحقق منه
    /// </summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// When the email was verified
    /// وقت التحقق من البريد الإلكتروني
    /// </summary>
    public DateTime VerifiedAt { get; set; }
}
