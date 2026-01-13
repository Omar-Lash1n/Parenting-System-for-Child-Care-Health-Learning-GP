namespace Ajial.Application.DTOs.VoiceNote;

/// <summary>
/// استجابة رفع ملاحظة صوتية - Upload Voice Note Response DTO
/// </summary>
public class UploadVoiceNoteResponseDto
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
    /// حجم الملف بالبايت - File size in bytes
    /// </summary>
    public long FileSizeBytes { get; set; }

    /// <summary>
    /// تاريخ الإنشاء - Creation date
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// رسالة النجاح - Success message
    /// </summary>
    public string Message { get; set; } = string.Empty;
}
