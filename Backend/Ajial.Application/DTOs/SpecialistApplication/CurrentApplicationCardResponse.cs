namespace Ajial.Application.DTOs.SpecialistApplication;

public class CurrentApplicationCardResponse
{
    public Guid ApplicationId { get; set; }
    public Guid SpecialistId { get; set; }
    public string SpecialtyName { get; set; } = string.Empty;
    public DateTime? SubmittedAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public string? RejectionReason { get; set; }
    public bool CanView { get; set; }
    public bool CanEdit { get; set; }
    public bool CanCancel { get; set; }
    public bool CanCreateNew { get; set; }
    public string? PersonalPhotoUrl { get; set; }
}
