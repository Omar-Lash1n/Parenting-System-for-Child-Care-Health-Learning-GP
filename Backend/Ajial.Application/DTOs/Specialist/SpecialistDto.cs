namespace Ajial.Application.DTOs.Specialist;

public class SpecialistDto
{
    public Guid SpecialistId { get; set; }
    public Guid UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Specialization { get; set; } = string.Empty;
    public string PracticeLicenseNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;

    // Image URLs
    public string IdFrontImageUrl { get; set; } = string.Empty;
    public string? IdBackImageUrl { get; set; }
    public string SpecializationCertificateImageUrl { get; set; } = string.Empty;
    public string PracticeLicenseImageUrl { get; set; } = string.Empty;
    public string UnionCardImageUrl { get; set; } = string.Empty;
    public string PersonalPhotoUrl { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
