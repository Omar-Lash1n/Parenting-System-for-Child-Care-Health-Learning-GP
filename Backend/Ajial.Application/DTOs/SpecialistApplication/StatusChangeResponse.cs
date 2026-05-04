namespace Ajial.Application.DTOs.SpecialistApplication;

public class StatusChangeResponse
{
    public Guid ApplicationId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public DateTime? SubmittedAt { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public string? RejectionReason { get; set; }
}
