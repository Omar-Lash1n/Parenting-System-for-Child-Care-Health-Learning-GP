namespace Ajial.Application.DTOs.RemoteConsultation;

public class AdminRemoteConsultationDetailResponse
{
    public Guid ConsultationId { get; set; }
    public Guid SpecialistId { get; set; }
    public string DoctorName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public DateTime? SubmittedAt { get; set; }
    public string? RejectionReason { get; set; }

    public decimal? SessionPrice { get; set; }
    public int? SessionDurationMinutes { get; set; }
    public int? WaitingPeriodMinutes { get; set; }
    public string? WorkingHoursJson { get; set; }
}
