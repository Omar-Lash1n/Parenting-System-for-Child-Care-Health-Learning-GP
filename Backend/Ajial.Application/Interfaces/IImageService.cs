using Microsoft.AspNetCore.Http;

namespace Ajial.Application.Interfaces;

public interface IImageService
{
    Task<string> UploadChildImageAsync(IFormFile image, Guid childId);
    Task<bool> DeleteImageAsync(string imageUrl);
    string GetDefaultChildAvatar(string gender);
}