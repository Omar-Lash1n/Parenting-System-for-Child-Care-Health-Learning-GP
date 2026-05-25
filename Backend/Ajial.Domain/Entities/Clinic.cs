namespace Ajial.Domain.Entities;

public class Clinic
{
    public Guid Id { get; set; }
    public Guid SpecialistId { get; set; }
    public Specialist Specialist { get; set; } = null!;

    // Step 1 — clinic details
    public string? Name { get; set; }
    public int? GovernorateId { get; set; }
    public City? Governorate { get; set; }
    public string? DistrictName { get; set; }
    public string? Address { get; set; }
    public string? Phone { get; set; }

    // Step 2 — hours & pricing
    public string? WorkingHoursJson { get; set; }
    public decimal? ExaminationPrice { get; set; }
    public decimal? ConsultationPrice { get; set; }

    // Step 3 — clinic documents (Azure Blob URLs)
    public string? LicenseImageUrl { get; set; }
    public string? SyndicateRegistrationImageUrl { get; set; }
    public string? HazardousWasteImageUrl { get; set; }
    public string? ExteriorImageUrl { get; set; }
    public string? InteriorImageUrl { get; set; }

    // Status
    public ClinicStatus Status { get; set; } = ClinicStatus.Draft;
    public string? RejectionReason { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? SubmittedAt { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public Guid? ReviewedByUserId { get; set; }
}
