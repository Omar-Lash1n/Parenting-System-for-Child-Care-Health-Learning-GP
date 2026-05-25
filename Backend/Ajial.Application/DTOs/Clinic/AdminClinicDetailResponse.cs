namespace Ajial.Application.DTOs.Clinic;

public class AdminClinicDetailResponse
{
    public Guid ClinicId { get; set; }
    public Guid SpecialistId { get; set; }
    public string DoctorName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public DateTime? SubmittedAt { get; set; }
    public string? RejectionReason { get; set; }

    public string? Name { get; set; }
    public string? GovernorateName { get; set; }
    public string? DistrictName { get; set; }
    public string? Address { get; set; }
    public string? Phone { get; set; }
    public string? WorkingHoursJson { get; set; }
    public decimal? ExaminationPrice { get; set; }
    public decimal? ConsultationPrice { get; set; }

    public string? LicenseImageUrl { get; set; }
    public string? SyndicateRegistrationImageUrl { get; set; }
    public string? HazardousWasteImageUrl { get; set; }
    public string? ExteriorImageUrl { get; set; }
    public string? InteriorImageUrl { get; set; }
}
