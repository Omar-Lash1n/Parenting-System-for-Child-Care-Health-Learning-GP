namespace Ajial.Domain.Entities;

public class Specialist
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public string Phone { get; set; } = string.Empty;
    public string Specialization { get; set; } = string.Empty;
    public string PracticeLicenseNumber { get; set; } = string.Empty;

    // Image URLs (stored in Azure Blob Storage)
    public string IdFrontImageUrl { get; set; } = string.Empty;
    public string? IdBackImageUrl { get; set; }
    public string SpecializationCertificateImageUrl { get; set; } = string.Empty;
    public string PracticeLicenseImageUrl { get; set; } = string.Empty;
    public string UnionCardImageUrl { get; set; } = string.Empty;
    public string PersonalPhotoUrl { get; set; } = string.Empty;

    public SpecialistStatus Status { get; set; } = SpecialistStatus.Pending;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
