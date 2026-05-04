namespace Ajial.Application.DTOs.SpecialistApplication;

public class ProfessionalDataDto
{
    public string SpecialtyName { get; set; } = string.Empty;
    public int? SpecialtyId { get; set; }
    public string? SpecializationCertificateUrl { get; set; }
    public bool SpecializationCertificateUploaded { get; set; }
    public string PracticeLicenseNumber { get; set; } = string.Empty;
    public string? ProfessionalLicenseUrl { get; set; }
    public bool ProfessionalLicenseUploaded { get; set; }
    public string? SyndicateCardUrl { get; set; }
    public bool SyndicateCardUploaded { get; set; }
}
