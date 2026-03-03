using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.Child;

public class CreateChildAccountDto
{
    /// <summary>
    /// كود الطفل - 4 أرقام فريدة لتسجيل الدخول
    /// </summary>
    [Required(ErrorMessage = "كود الطفل مطلوب")]
    public string ChildLoginId { get; set; } = string.Empty;

    /// <summary>
    /// كلمة المرور - 5 فواكه مختارة
    /// </summary>
    [Required(ErrorMessage = "كلمة المرور مطلوبة")]
    [MinLength(5, ErrorMessage = "يجب اختيار 5 فواكه لكلمة المرور")]
    [MaxLength(5, ErrorMessage = "يجب اختيار 5 فواكه فقط لكلمة المرور")]
    public List<string> FruitPasswordCodes { get; set; } = new();
}
