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
}