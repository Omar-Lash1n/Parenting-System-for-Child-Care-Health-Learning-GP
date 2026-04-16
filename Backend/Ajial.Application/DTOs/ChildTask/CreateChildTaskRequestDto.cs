using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.ChildTask;

/// <summary>
/// يُرسل كـ multipart/form-data
/// الحقول الإلزامية الوحيدة: Title و SelectedChildIds
/// كل الحقول الأخرى اختيارية — يمكن إرسال قيمة فارغة أو تجاهلها
/// </summary>
public class CreateChildTaskRequestDto
{
    [Required(ErrorMessage = "عنوان المهمة مطلوب")]
    [StringLength(200, MinimumLength = 1, ErrorMessage = "عنوان المهمة يجب أن يكون بين 1 و 200 حرف")]
    public string Title { get; set; } = string.Empty;

    /// <summary>صورة المهمة (اختياري) — JPEG/PNG/WebP/GIF, max 5 MB</summary>
    public IFormFile? TaskImage { get; set; }

    /// <summary>ملف التسجيل الصوتي (اختياري) — يشرح المهمة للطفل، max 10 MB</summary>
    public IFormFile? Recording { get; set; }

    /// <summary>عدد النجوم — اختياري، القيمة الافتراضية 0</summary>
    [Range(0, 100, ErrorMessage = "عدد النجوم يجب أن يكون بين 0 و 100")]
    public int Stars { get; set; } = 0;

    /// <summary>تاريخ البدء — اختياري</summary>
    public DateTime? StartDate { get; set; }

    /// <summary>تاريخ الانتهاء — اختياري</summary>
    public DateTime? DueDate { get; set; }

    /// <summary>
    /// معرفات الأطفال المحددين (مطلوب) — يُرسل كحقول متعددة:
    /// selectedChildIds=id1&amp;selectedChildIds=id2
    /// </summary>
    [Required(ErrorMessage = "يجب اختيار طفل واحد على الأقل")]
    [MinLength(1, ErrorMessage = "يجب اختيار طفل واحد على الأقل")]
    public List<Guid> SelectedChildIds { get; set; } = new();

    // ── Recurrence (اختياري — كلها) ──────────────────────────────────────────

    /// <summary>هل المهمة متكررة؟ — اختياري، القيمة الافتراضية false</summary>
    public bool IsRecurring { get; set; } = false;

    /// <summary>أيام التكرار بفاصلة — اختياري — e.g. "saturday,thursday"</summary>
    public string? RepeatDays { get; set; }

    /// <summary>وقت التكرار بصيغة HH:mm — اختياري — e.g. "08:00"</summary>
    public string? RepeatTime { get; set; }
}
