namespace Ajial.Application.DTOs.SpecialistApplication;

public class ApplicationDetailsResponse
{
    public Guid ApplicationId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public DateTime? SubmittedAt { get; set; }
    public string? RejectionReason { get; set; }
    public IdentityDataDto IdentityData { get; set; } = new();
    public ProfessionalDataDto ProfessionalData { get; set; } = new();
    public bool CanEdit { get; set; }
    public bool CanCancel { get; set; }
}
