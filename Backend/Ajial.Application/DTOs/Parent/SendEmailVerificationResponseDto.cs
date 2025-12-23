namespace Ajial.Application.DTOs.Parent;

/// <summary>
/// Response after sending email verification
/// الاستجابة بعد إرسال رابط التحقق من البريد الإلكتروني
/// </summary>
public class SendEmailVerificationResponseDto
{
    /// <summary>
    /// Success message
    /// رسالة النجاح
    /// </summary>
    public string Message { get; set; } = string.Empty;

    /// <summary>
    /// Email address verification was sent to
    /// البريد الإلكتروني الذي تم إرسال التحقق إليه
    /// </summary>
    public string Email { get; set; } = string.Empty;

    /// <summary>
    /// When the verification email was sent
    /// وقت إرسال رسالة التحقق
    /// </summary>
    public DateTime SentAt { get; set; }
}
