namespace Ajial.Domain.Entities;

/// <summary>
/// ملاحظة صوتية للطفل - Child Voice Note Entity
/// Used as a psychological outlet for children to express their feelings
/// </summary>
public class VoiceNote
{
    public Guid Id { get; set; }
    public Guid ChildId { get; set; }
    public Child Child { get; set; } = null!;

    /// <summary>
    /// عنوان الملاحظة الصوتية - Voice note title
    /// </summary>
    public string Title { get; set; } = string.Empty;

    /// <summary>
    /// رابط الملف في Azure Blob Storage
    /// </summary>
    public string BlobUrl { get; set; } = string.Empty;

    /// <summary>
    /// اسم الملف الأصلي - Original file name
    /// </summary>
    public string FileName { get; set; } = string.Empty;

    /// <summary>
    /// حجم الملف بالبايت - File size in bytes
    /// </summary>
    public long FileSizeBytes { get; set; }

    /// <summary>
    /// نوع المحتوى - Content type (e.g., audio/mp3)
    /// </summary>
    public string ContentType { get; set; } = string.Empty;

    /// <summary>
    /// تاريخ الإنشاء - Creation date
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// هل الملاحظة نشطة - Is voice note active
    /// </summary>
    public bool IsActive { get; set; } = true;
}
