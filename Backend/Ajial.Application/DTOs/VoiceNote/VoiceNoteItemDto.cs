namespace Ajial.Application.DTOs.VoiceNote;

/// <summary>
/// استجابة قائمة الملاحظات الصوتية - Voice Note List Item Response DTO
/// </summary>
public class VoiceNoteItemDto
{
    /// <summary>
    /// معرف الملاحظة الصوتية - Voice note ID
    /// </summary>
    public Guid VoiceNoteId { get; set; }

    /// <summary>
    /// عنوان الملاحظة الصوتية - Voice note title
    /// </summary>
    public string Title { get; set; } = string.Empty;

    /// <summary>
    /// رابط الملف في Azure Blob Storage
    /// </summary>
    public string BlobUrl { get; set; } = string.Empty;

    /// <summary>
    /// تاريخ الإنشاء - Creation date
    /// </summary>
    public DateTime CreatedAt { get; set; }
}
