namespace Ajial.Application.DTOs.Clinic;

public class ClinicDetailResponse
{
    public Guid ClinicId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public DateTime? SubmittedAt { get; set; }
    public string? RejectionReason { get; set; }

    // Step 1
    public string? Name { get; set; }
    public int? GovernorateId { get; set; }
    public string? GovernorateName { get; set; }
    public string? DistrictName { get; set; }
    public string? Address { get; set; }
    public string? Phone { get; set; }

    // Step 2
    public string? WorkingHoursJson { get; set; }
    public decimal? ExaminationPrice { get; set; }
    public decimal? ConsultationPrice { get; set; }

    // Step 3
    public string? LicenseImageUrl { get; set; }
    public string? SyndicateRegistrationImageUrl { get; set; }
    public string? HazardousWasteImageUrl { get; set; }
    public string? ExteriorImageUrl { get; set; }
    public string? InteriorImageUrl { get; set; }

    public bool CanEdit { get; set; }
    public bool CanCancel { get; set; }
    public bool CanSubmit { get; set; }
}
