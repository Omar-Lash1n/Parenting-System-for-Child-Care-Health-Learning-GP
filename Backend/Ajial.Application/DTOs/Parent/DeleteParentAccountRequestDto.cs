namespace Ajial.Application.DTOs.Parent;

/// <summary>
/// Request to delete parent account permanently
/// طلب حذف حساب ولي الأمر نهائياً
/// </summary>
public class DeleteParentAccountRequestDto
{
    /// <summary>
    /// Confirmation text - user must type "حذف" to confirm deletion
    /// نص التأكيد - يجب على المستخدم كتابة "حذف" لتأكيد الحذف
    /// </summary>
    public string ConfirmationText { get; set; } = string.Empty;
}
