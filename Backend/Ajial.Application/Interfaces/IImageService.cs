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
}
