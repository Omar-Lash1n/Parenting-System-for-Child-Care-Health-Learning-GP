using Microsoft.AspNetCore.Http;

namespace Ajial.Application.DTOs.Clinic;

public class UploadClinicDocumentRequest
{
    public IFormFile File { get; set; } = null!;
}
