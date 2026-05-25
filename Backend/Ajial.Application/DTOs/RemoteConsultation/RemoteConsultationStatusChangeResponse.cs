namespace Ajial.Application.DTOs.RemoteConsultation;

public class RemoteConsultationStatusChangeResponse
{
    public Guid ConsultationId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
}
