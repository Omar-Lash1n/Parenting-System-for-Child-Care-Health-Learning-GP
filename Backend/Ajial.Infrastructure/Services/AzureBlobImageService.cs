using Ajial.Application.Interfaces;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;

namespace Ajial.Infrastructure.Services;

public class AzureBlobImageService : IImageService
{
    private readonly BlobServiceClient _blobServiceClient;
    private readonly string _containerName;
    private readonly IConfiguration _configuration;

    public AzureBlobImageService(IConfiguration configuration)
    {
        _configuration = configuration;
        var connectionString = configuration["AzureStorage:ConnectionString"];
        _containerName = configuration["AzureStorage:ContainerName"] ?? "child-images";

        if (string.IsNullOrEmpty(connectionString))
        {
            throw new InvalidOperationException("Azure Storage connection string not found");
        }

        _blobServiceClient = new BlobServiceClient(connectionString);
    }

    public async Task<string> UploadChildImageAsync(IFormFile image, Guid childId)
    {
        try
        {
            var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
            await containerClient.CreateIfNotExistsAsync(PublicAccessType.Blob);

            var extension = Path.GetExtension(image.FileName).ToLowerInvariant();
            var timestamp = DateTime.UtcNow.ToString("yyyyMMddHHmmss");
            var blobName = $"child-{childId}-{timestamp}{extension}";

            var blobClient = containerClient.GetBlobClient(blobName);

            var blobHttpHeaders = new BlobHttpHeaders
            {
                ContentType = image.ContentType,
                CacheControl = "public, max-age=31536000"
            };

            using var stream = image.OpenReadStream();
            await blobClient.UploadAsync(stream, new BlobUploadOptions
            {
                HttpHeaders = blobHttpHeaders
            });

            return blobClient.Uri.ToString();
        }
        catch (Exception ex)
        {
            throw new Exception($"فشل في رفع الصورة: {ex.Message}", ex);
        }
    }

    public async Task<bool> DeleteImageAsync(string imageUrl)
    {
        try
        {
            if (string.IsNullOrEmpty(imageUrl))
                return false;

            var uri = new Uri(imageUrl);
            var segments = uri.Segments;
            var blobName = segments[segments.Length - 1];

            var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
            var blobClient = containerClient.GetBlobClient(blobName);

            return await blobClient.DeleteIfExistsAsync();
        }
        catch
        {
            return false;
        }
    }

    public string GetDefaultChildAvatar(string gender)
    {
        var baseUrl = _configuration["AzureStorage:DefaultAvatarsUrl"]
                      ?? "https://ajialchildimages.blob.core.windows.net/defaults";

        return gender.ToLower() switch
        {
            "ذكر" or "male" => $"{baseUrl}/boy-default.png",
            "أنثى" or "female" => $"{baseUrl}/girl-default.png",
            _ => $"{baseUrl}/child-default.png"
        };
    }

    /// <summary>
    /// Upload parent profile image to Azure Blob Storage
    /// </summary>
    public async Task<string> UploadParentImageAsync(IFormFile image, Guid parentId)
    {
        if (image == null || image.Length == 0)
        {
            throw new ArgumentException("الصورة فارغة");
        }

        // Validate image (size, format, etc.)
        ValidateImage(image);

        // Get container client
        var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
        await containerClient.CreateIfNotExistsAsync(PublicAccessType.Blob);

        // Generate unique filename
        var extension = Path.GetExtension(image.FileName).ToLowerInvariant();
        var uniqueFileName = $"parent_{parentId}_{Guid.NewGuid()}{extension}";
        var blobName = $"parents/{uniqueFileName}";

        // Get blob client
        var blobClient = containerClient.GetBlobClient(blobName);

        // Set content type
        var blobHttpHeaders = new BlobHttpHeaders
        {
            ContentType = image.ContentType
        };

        // Upload file
        using (var stream = image.OpenReadStream())
        {
            await blobClient.UploadAsync(stream, new BlobUploadOptions
            {
                HttpHeaders = blobHttpHeaders
            });
        }

        return blobClient.Uri.ToString();
    }

    /// <summary>
    /// Validate image file (if not already exists)
    /// </summary>
    private void ValidateImage(IFormFile image)
    {
        // Max 5MB
        const long maxSizeInBytes = 5 * 1024 * 1024;

        if (image.Length > maxSizeInBytes)
        {
            throw new ArgumentException($"حجم الصورة يجب ألا يتجاوز {maxSizeInBytes / (1024 * 1024)} ميجابايت");
        }

        // Allowed extensions
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png" };
        var extension = Path.GetExtension(image.FileName).ToLowerInvariant();

        if (!allowedExtensions.Contains(extension))
        {
            throw new ArgumentException(
                $"نوع الملف غير مدعوم.  الأنواع المسموحة: {string.Join(", ", allowedExtensions)}");
        }

        // Allowed MIME types
        var allowedMimeTypes = new[] { "image/jpeg", "image/jpg", "image/png" };

        if (!allowedMimeTypes.Contains(image.ContentType.ToLowerInvariant()))
        {
            throw new ArgumentException("نوع الصورة غير صحيح");
        }
    }

    /// <summary>
    /// Upload voice note to Azure Blob Storage
    /// </summary>
    public async Task<string> UploadVoiceNoteAsync(IFormFile voiceNote, Guid childId, string fileName)
    {
        try
        {
            var containerClient = _blobServiceClient.GetBlobContainerClient(_containerName);
            await containerClient.CreateIfNotExistsAsync(PublicAccessType.Blob);

            // Store in voice-notes/{childId}/ subfolder
            var blobName = $"voice-notes/{childId}/{fileName}";

            var blobClient = containerClient.GetBlobClient(blobName);

            var blobHttpHeaders = new BlobHttpHeaders
            {
                ContentType = voiceNote.ContentType,
                CacheControl = "public, max-age=31536000"
            };

            using var stream = voiceNote.OpenReadStream();
            await blobClient.UploadAsync(stream, new BlobUploadOptions
            {
                HttpHeaders = blobHttpHeaders
            });

            return blobClient.Uri.ToString();
        }
        catch (Exception ex)
        {
            throw new Exception($"فشل في رفع الملاحظة الصوتية: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// Upload specialist document/image to Azure Blob Storage (specialist-images container)
    /// </summary>
    public async Task<string> UploadSpecialistImageAsync(IFormFile image, Guid specialistId, string subfolder)
    {
        if (image == null || image.Length == 0)
        {
            throw new ArgumentException("الصورة فارغة");
        }

        // Validate image (size, format, etc.)
        ValidateImage(image);

        // Use specialist-images container
        var specialistContainerName = _configuration["AzureStorage:SpecialistContainerName"] ?? "specialist-images";
        var containerClient = _blobServiceClient.GetBlobContainerClient(specialistContainerName);
        await containerClient.CreateIfNotExistsAsync(PublicAccessType.Blob);

        // Generate unique filename with subfolder organization
        var extension = Path.GetExtension(image.FileName).ToLowerInvariant();
        var uniqueFileName = $"specialist_{specialistId}_{Guid.NewGuid()}{extension}";
        var blobName = $"{subfolder}/{uniqueFileName}";

        // Get blob client
        var blobClient = containerClient.GetBlobClient(blobName);

        // Set content type
        var blobHttpHeaders = new BlobHttpHeaders
        {
            ContentType = image.ContentType,
            CacheControl = "public, max-age=31536000"
        };

        // Upload file
        using var stream = image.OpenReadStream();
        await blobClient.UploadAsync(stream, new BlobUploadOptions
        {
            HttpHeaders = blobHttpHeaders
        });

        return blobClient.Uri.ToString();
    }

    /// <summary>
    /// Upload task recording to Azure Blob Storage (child-tasks-recording container)
    /// Blob path: task-recordings/{parentId}/rec-{guid}.{extension}
    /// </summary>
    public async Task<string> UploadChildTaskRecordingAsync(IFormFile recording, Guid parentId)
    {
        try
        {
            // Validate size (max 10 MB)
            const long maxSizeInBytes = 10 * 1024 * 1024;
            if (recording.Length > maxSizeInBytes)
                throw new ArgumentException("حجم التسجيل يجب ألا يتجاوز 10 ميجابايت");

            // Validate content type
            var allowedTypes = new[] { "audio/mpeg", "audio/mp4", "audio/aac", "audio/wav", "audio/x-m4a", "audio/ogg", "audio/webm" };
            if (!allowedTypes.Contains(recording.ContentType.ToLowerInvariant()))
                throw new ArgumentException("نوع الملف غير مدعوم. يُسمح فقط بملفات الصوت");

            var recordingContainerName = _configuration["AzureStorage:ChildTaskRecordingContainerName"] ?? "child-tasks-recording";
            var containerClient = _blobServiceClient.GetBlobContainerClient(recordingContainerName);
            await containerClient.CreateIfNotExistsAsync(PublicAccessType.Blob);

            var extension = Path.GetExtension(recording.FileName).ToLowerInvariant();
            if (string.IsNullOrEmpty(extension)) extension = ".m4a";

            var blobName = $"task-recordings/{parentId}/rec-{Guid.NewGuid()}{extension}";
            var blobClient = containerClient.GetBlobClient(blobName);

            var blobHttpHeaders = new BlobHttpHeaders
            {
                ContentType = recording.ContentType,
                CacheControl = "public, max-age=31536000"
            };

            using var stream = recording.OpenReadStream();
            await blobClient.UploadAsync(stream, new BlobUploadOptions
            {
                HttpHeaders = blobHttpHeaders
            });

            return blobClient.Uri.ToString();
        }
        catch (ArgumentException)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw new Exception($"فشل في رفع التسجيل الصوتي: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// Upload task illustration image to Azure Blob Storage (child-task-images container)
    /// Blob path: task-images/{parentId}/img-{guid}.{extension}
    /// </summary>
    public async Task<string> UploadChildTaskImageAsync(IFormFile image, Guid parentId)
    {
        try
        {
            // Validate size (max 5 MB)
            const long maxSizeInBytes = 5 * 1024 * 1024;
            if (image.Length > maxSizeInBytes)
                throw new ArgumentException("حجم الصورة يجب ألا يتجاوز 5 ميجابايت");

            // Validate content type
            var allowedTypes = new[] { "image/jpeg", "image/png", "image/webp", "image/gif" };
            if (!allowedTypes.Contains(image.ContentType.ToLowerInvariant()))
                throw new ArgumentException("نوع الملف غير مدعوم. يُسمح فقط بـ JPEG أو PNG أو WebP أو GIF");

            var imageContainerName = _configuration["AzureStorage:ChildTaskImageContainerName"] ?? "child-task-images";
            var containerClient = _blobServiceClient.GetBlobContainerClient(imageContainerName);
            await containerClient.CreateIfNotExistsAsync(PublicAccessType.Blob);

            var extension = Path.GetExtension(image.FileName).ToLowerInvariant();
            if (string.IsNullOrEmpty(extension)) extension = ".jpg";

            var blobName = $"task-images/{parentId}/img-{Guid.NewGuid()}{extension}";
            var blobClient = containerClient.GetBlobClient(blobName);

            var blobHttpHeaders = new BlobHttpHeaders
            {
                ContentType = image.ContentType,
                CacheControl = "public, max-age=31536000"
            };

            using var stream = image.OpenReadStream();
            await blobClient.UploadAsync(stream, new BlobUploadOptions
            {
                HttpHeaders = blobHttpHeaders
            });

            return blobClient.Uri.ToString();
        }
        catch (ArgumentException)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw new Exception($"فشل في رفع صورة المهمة: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// Upload prize image to Azure Blob Storage (prize-images container)
    /// Blob path: prize-images/{userId}/img-{guid}.{extension}
    /// </summary>
    public async Task<string> UploadPrizeImageAsync(IFormFile file, Guid userId)
    {
        try
        {
            const long maxSizeInBytes = 5 * 1024 * 1024;
            if (file.Length > maxSizeInBytes)
                throw new ArgumentException("حجم الصورة يجب ألا يتجاوز 5 ميجابايت");

            var allowedTypes = new[] { "image/jpeg", "image/png", "image/webp", "image/gif" };
            if (!allowedTypes.Contains(file.ContentType.ToLowerInvariant()))
                throw new ArgumentException("نوع الملف غير مدعوم. يُسمح فقط بـ JPEG أو PNG أو WebP أو GIF");

            var containerClient = _blobServiceClient.GetBlobContainerClient("prize-images");
            await containerClient.CreateIfNotExistsAsync(PublicAccessType.Blob);

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (string.IsNullOrEmpty(extension)) extension = ".jpg";

            var blobName = $"prize-images/{userId}/img-{Guid.NewGuid()}{extension}";
            var blobClient = containerClient.GetBlobClient(blobName);

            var blobHttpHeaders = new BlobHttpHeaders
            {
                ContentType = file.ContentType,
                CacheControl = "public, max-age=31536000"
            };

            using var stream = file.OpenReadStream();
            await blobClient.UploadAsync(stream, new BlobUploadOptions
            {
                HttpHeaders = blobHttpHeaders
            });

            return blobClient.Uri.ToString();
        }
        catch (ArgumentException)
        {
            throw;
        }
        catch (Exception ex)
        {
            throw new Exception($"فشل في رفع صورة الجائزة: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// Delete a blob by its full Azure URL — parses container name from URL path.
    /// Works cross-container unlike DeleteImageAsync (which uses only the default container).
    /// URL format: https://{account}.blob.core.windows.net/{container}/{blobPath}
    /// </summary>
    public async Task<bool> DeleteBlobByUrlAsync(string blobUrl)
    {
        try
        {
            if (string.IsNullOrEmpty(blobUrl))
                return false;

            var uri = new Uri(blobUrl);
            // uri.Segments: ["/", "container/", "path/", "file.ext"]
            var segments = uri.Segments;
            if (segments.Length < 3)
                return false;

            var containerName = segments[1].TrimEnd('/');
            var blobName = string.Concat(segments.Skip(2)).TrimStart('/');

            var containerClient = _blobServiceClient.GetBlobContainerClient(containerName);
            var blobClient = containerClient.GetBlobClient(blobName);

            return await blobClient.DeleteIfExistsAsync();
        }
        catch
        {
            return false;
        }
    }

    public async Task<string> UploadClinicImageAsync(IFormFile file, Guid clinicId, string subfolder)
    {
        if (file == null || file.Length == 0)
            throw new ArgumentException("الملف فارغ");

        ValidateImage(file);

        var clinicContainerName = _configuration["AzureStorage:ClinicContainerName"] ?? "clinic-documents";
        var containerClient = _blobServiceClient.GetBlobContainerClient(clinicContainerName);
        await containerClient.CreateIfNotExistsAsync(PublicAccessType.Blob);

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        var blobName = $"{subfolder}/clinic_{clinicId}_{Guid.NewGuid()}{extension}";
        var blobClient = containerClient.GetBlobClient(blobName);

        var headers = new BlobHttpHeaders { ContentType = file.ContentType, CacheControl = "public, max-age=31536000" };
        using var stream = file.OpenReadStream();
        await blobClient.UploadAsync(stream, new BlobUploadOptions { HttpHeaders = headers });

        return blobClient.Uri.ToString();
    }
}
