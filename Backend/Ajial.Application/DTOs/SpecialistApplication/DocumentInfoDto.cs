namespace Ajial.Application.DTOs.SpecialistApplication;

public class DocumentInfoDto
{
    public string DocumentType { get; set; } = string.Empty;
    public string? DocumentUrl { get; set; }
    public bool Uploaded { get; set; }
}
