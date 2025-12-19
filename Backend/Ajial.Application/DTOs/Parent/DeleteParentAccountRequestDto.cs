namespace Ajial.Application.DTOs.Parent;

/// <summary>
/// Request to delete parent account permanently
/// طلب حذف حساب ولي الأمر نهائياً
/// </summary>
public class DeleteParentAccountRequestDto
{
    /// <summary>
    /// Current password for verification (security measure)
    /// كلمة المرور الحالية للتحقق (إجراء أمني)
    /// </summary>
    public string Password { get; set; } = string.Empty;
}
