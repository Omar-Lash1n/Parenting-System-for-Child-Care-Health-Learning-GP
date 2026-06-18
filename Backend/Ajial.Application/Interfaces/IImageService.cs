using Microsoft.AspNetCore.Http;

namespace Ajial.Application.Interfaces;

public interface IImageService
{
    Task<string> UploadChildImageAsync(IFormFile image, Guid childId);
    Task<bool> DeleteImageAsync(string imageUrl);
    string GetDefaultChildAvatar(string gender);
    Task<string> UploadParentImageAsync(IFormFile image, Guid parentId);
    Task<string> UploadVoiceNoteAsync(IFormFile voiceNote, Guid childId, string fileName);
    Task<string> UploadSpecialistImageAsync(IFormFile image, Guid specialistId, string subfolder);

    /// <summary>رفع تسجيل صوتي لمهمة طفل إلى حاوية child-tasks-recording</summary>
    Task<string> UploadChildTaskRecordingAsync(IFormFile recording, Guid parentId);

    /// <summary>رفع صورة مهمة طفل إلى حاوية child-task-images</summary>
    Task<string> UploadChildTaskImageAsync(IFormFile image, Guid parentId);

    /// <summary>رفع صورة جائزة إلى حاوية prize-images</summary>
    Task<string> UploadPrizeImageAsync(IFormFile file, Guid userId);

    /// <summary>
    /// حذف blob من أي حاوية بناءً على الرابط الكامل
    /// يُستخدم عند حذف تسجيل أو صورة من حاوية مختلفة عن الحاوية الافتراضية
    /// </summary>
    Task<bool> DeleteBlobByUrlAsync(string blobUrl);

    /// <summary>رفع مستند عيادة إلى حاوية clinic-documents</summary>
    Task<string> UploadClinicImageAsync(IFormFile file, Guid clinicId, string subfolder);

    /// <summary>رفع صورة مرفقة بحجز (تحاليل/أشعة) إلى حاوية consultation-images</summary>
    Task<string> UploadBookingAttachmentAsync(IFormFile file, Guid parentId);

    /// <summary>رفع صورة إيصال دفع إلى حاوية consultation-images</summary>
    Task<string> UploadPaymentReceiptAsync(IFormFile file, Guid parentId);

    /// <summary>
    /// رفع ملف الـ PDF للملف الطبي الموحد للطفل إلى حاوية medical-files.
    /// يُخزَّن في مسار ثابت لكل طفل (medical-files/{childId}/passport.pdf) ويُستبدل عند إعادة التوليد.
    /// يعيد رابطاً يتضمن مُبطّل تخزين مؤقت (?v=timestamp) لضمان جلب أحدث نسخة.
    /// </summary>
    Task<string> UploadMedicalFileAsync(byte[] pdfBytes, Guid childId);
}
