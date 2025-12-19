namespace Ajial.Application.DTOs.Parent;

/// <summary>
/// Response after successfully deleting parent account
/// الاستجابة بعد حذف حساب ولي الأمر بنجاح
/// </summary>
public class DeleteParentAccountResponseDto
{
    /// <summary>
    /// Success message
    /// رسالة النجاح
    /// </summary>
    public string Message { get; set; } = string.Empty;

    /// <summary>
    /// When the account was deleted
    /// وقت حذف الحساب
    /// </summary>
    public DateTime DeletedAt { get; set; }

    /// <summary>
    /// Number of children deleted with the account
    /// عدد الأطفال المحذوفين مع الحساب
    /// </summary>
    public int ChildrenDeleted { get; set; }
}
