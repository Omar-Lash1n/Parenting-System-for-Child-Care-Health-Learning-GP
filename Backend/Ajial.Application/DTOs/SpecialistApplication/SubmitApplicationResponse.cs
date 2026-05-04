namespace Ajial.Application.DTOs.SpecialistApplication;

public class SubmitApplicationResponse
{
    public Guid ApplicationId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public DateTime? SubmittedAt { get; set; }
}
