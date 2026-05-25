namespace Ajial.Application.DTOs.Clinic;

public class ClinicCardResponse
{
    public Guid ClinicId { get; set; }
    public string? Name { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public DateTime? SubmittedAt { get; set; }
    public string? RejectionReason { get; set; }
    public bool CanEdit { get; set; }
    public bool CanCancel { get; set; }
    public bool CanSubmit { get; set; }
}
