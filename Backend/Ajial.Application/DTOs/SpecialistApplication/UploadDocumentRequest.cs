using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace Ajial.Application.DTOs.SpecialistApplication;

public class UploadDocumentRequest
{
    [Required(ErrorMessage = "الملف مطلوب")]
    public IFormFile File { get; set; } = null!;
}
