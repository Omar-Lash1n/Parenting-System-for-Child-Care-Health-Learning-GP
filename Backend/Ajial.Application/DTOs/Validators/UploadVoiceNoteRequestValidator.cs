using Ajial.Application.DTOs.VoiceNote;

namespace Ajial.Application.DTOs.Validators;

/// <summary>
/// Validator for UploadVoiceNoteRequestDto
/// Validates audio file format and size
/// </summary>
public class UploadVoiceNoteRequestValidator
{
    // Allowed audio formats
    private static readonly string[] AllowedExtensions = { ".mp3", ".wav", ".m4a", ".ogg", ".webm" };

    // Allowed MIME types
    private static readonly string[] AllowedMimeTypes =
    {
        "audio/mpeg",       // .mp3
        "audio/mp3",        // .mp3 (alternative)
        "audio/wav",        // .wav
        "audio/wave",       // .wav (alternative)
        "audio/x-wav",      // .wav (alternative)
        "audio/m4a",        // .m4a
        "audio/x-m4a",      // .m4a (alternative)
        "audio/mp4",        // .m4a (alternative)
        "audio/ogg",        // .ogg
        "audio/webm"        // .webm
    };

    // Maximum file size: 10 MB
    private const long MaxFileSizeBytes = 10 * 1024 * 1024;

    // Maximum title length
    private const int MaxTitleLength = 100;

    public (bool IsValid, List<string> Errors) Validate(UploadVoiceNoteRequestDto request)
    {
        var errors = new List<string>();

        // Validate voice note file exists
        if (request.VoiceNote == null || request.VoiceNote.Length == 0)
        {
            errors.Add("الملف الصوتي مطلوب");
            return (false, errors);
        }

        // Validate file extension
        var extension = Path.GetExtension(request.VoiceNote.FileName).ToLowerInvariant();
        if (!AllowedExtensions.Contains(extension))
        {
            errors.Add($"نوع الملف غير مدعوم. الأنواع المسموحة: {string.Join(", ", AllowedExtensions)}");
        }

        // Validate MIME type
        var contentType = request.VoiceNote.ContentType.ToLowerInvariant();
        if (!AllowedMimeTypes.Contains(contentType))
        {
            errors.Add("نوع المحتوى غير صحيح للملف الصوتي");
        }

        // Validate file size
        if (request.VoiceNote.Length > MaxFileSizeBytes)
        {
            var maxSizeMB = MaxFileSizeBytes / (1024 * 1024);
            errors.Add($"حجم الملف يجب ألا يتجاوز {maxSizeMB} ميجابايت");
        }

        // Validate title length (if provided)
        if (!string.IsNullOrEmpty(request.Title) && request.Title.Length > MaxTitleLength)
        {
            errors.Add($"العنوان يجب ألا يتجاوز {MaxTitleLength} حرف");
        }

        return (errors.Count == 0, errors);
    }
}
