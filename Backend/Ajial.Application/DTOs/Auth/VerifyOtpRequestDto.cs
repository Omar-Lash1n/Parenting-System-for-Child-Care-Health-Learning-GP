using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.Auth;

public class VerifyOtpRequestDto
{
    [Required(ErrorMessage = "الرمز مطلوب")]
    [StringLength(6, MinimumLength = 6, ErrorMessage = "الرمز يجب أن يكون 6 أرقام")]
    public string Token { get; set; } = string.Empty;
}