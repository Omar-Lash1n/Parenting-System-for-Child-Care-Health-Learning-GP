namespace Ajial.Application.DTOs.ChildTask;

/// <summary>
/// بيانات الطفل مع حالة الأهلية — مستخدم في قائمة الأطفال بصفحة "مهام أطفالي"
/// </summary>
public class ChildForTasksDto
{
    public Guid ChildId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public DateTime BirthDate { get; set; }
    public int AgeYears { get; set; }
    public int AgeMonths { get; set; }
    public string Gender { get; set; } = string.Empty;

    /// <summary>true إذا كان عمر الطفل أقل من 4 سنوات</summary>
    public bool ChildTasksLocked { get; set; }

    /// <summary>سبب القفل — موجود فقط إذا كان ChildTasksLocked = true</summary>
    public string? LockedReason { get; set; }

    /// <summary>هل يوجد حساب للطفل؟ (أي ChildLoginId ليس null)</summary>
    public bool HasAccount { get; set; }

    /// <summary>هل الحساب نشط؟</summary>
    public bool IsAccountActive { get; set; }

    /// <summary>
    /// حالة الطفل:
    /// "locked_by_age"    — عمر الطفل أقل من 4 سنوات
    /// "no_account"       — عمر الطفل 4+ لكن ليس له حساب بعد
    /// "account_inactive" — له حساب لكنه غير نشط
    /// "eligible"         — أهل للمهام
    /// </summary>
    public string ChildStatus { get; set; } = string.Empty;

    /// <summary>مجموع النجوم من المهام المنجزة</summary>
    public int TotalStars { get; set; }

    /// <summary>عدد المهام غير المنجزة</summary>
    public int PendingTasksCount { get; set; }
}
