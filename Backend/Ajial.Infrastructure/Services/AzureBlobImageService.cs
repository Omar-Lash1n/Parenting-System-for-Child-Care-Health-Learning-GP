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
}