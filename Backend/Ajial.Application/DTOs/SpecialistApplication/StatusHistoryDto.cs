namespace Ajial.Application.DTOs.SpecialistApplication;

public class StatusHistoryDto
{
    public string FromStatus { get; set; } = string.Empty;
    public string ToStatus { get; set; } = string.Empty;
    public DateTime ChangedAt { get; set; }
    public string? Reason { get; set; }
    public Guid ChangedByUserId { get; set; }
}
