using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.VoiceNote;

/// <summary>
/// طلب رفع ملاحظة صوتية - Upload Voice Note Request DTO
/// </summary>
public class UploadVoiceNoteRequestDto
{
    /// <summary>
    /// ملف الصوت - Audio file
    /// Supported formats: .mp3, .wav, .m4a, .ogg, .webm
    /// Max size: 10 MB
    /// </summary>
    [Required(ErrorMessage = "الملف الصوتي مطلوب")]
    public IFormFile VoiceNote { get; set; } = null!;

    /// <summary>
    /// عنوان الملاحظة الصوتية - Voice note title (optional)
    /// Max length: 100 characters
    /// Default: Auto-generated timestamp-based title
    /// </summary>
    [MaxLength(100, ErrorMessage = "العنوان يجب ألا يتجاوز 100 حرف")]
    public string? Title { get; set; }
}
