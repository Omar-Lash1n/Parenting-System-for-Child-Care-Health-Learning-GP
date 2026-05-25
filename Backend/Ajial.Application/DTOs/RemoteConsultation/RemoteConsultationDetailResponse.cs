namespace Ajial.Application.DTOs.RemoteConsultation;

public class RemoteConsultationDetailResponse
{
    public Guid ConsultationId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public DateTime? SubmittedAt { get; set; }
    public string? RejectionReason { get; set; }

    public decimal? SessionPrice { get; set; }
    public int? SessionDurationMinutes { get; set; }
    public int? WaitingPeriodMinutes { get; set; }
    public string? WorkingHoursJson { get; set; }

    public bool CanEdit { get; set; }
    public bool CanCancel { get; set; }
    public bool CanSubmit { get; set; }
}
