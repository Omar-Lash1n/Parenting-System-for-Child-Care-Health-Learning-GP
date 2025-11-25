namespace Ajial.Application.DTOs.Auth;

/// <summary>
/// طلب تسجيل دخول الطفل
/// </summary>
public class LoginChildRequestDto
{
    /// <summary>
    /// معرف تسجيل الدخول للطفل (أرقام فقط)
    /// مثال: "4556"
    /// </summary>
    public string ChildLoginId { get; set; } = string.Empty;

    /// <summary>
    /// أكواد الفواكه (كلمة المرور البصرية - 5 فواكه بالترتيب)
    /// مثال: ["apple2025", "banana2025", "orange2025", "grape2025", "pear2025"]
    /// </summary>
    public List<string> FruitPasswordCodes { get; set; } = new();
}