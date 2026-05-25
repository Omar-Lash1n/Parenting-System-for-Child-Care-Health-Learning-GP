namespace Ajial.Application.DTOs.RemoteConsultation;

public class UpdateRemoteConsultationRequest
{
    public decimal? SessionPrice { get; set; }
    public int? SessionDurationMinutes { get; set; }
    public int? WaitingPeriodMinutes { get; set; }
    public string? WorkingHoursJson { get; set; }
}
