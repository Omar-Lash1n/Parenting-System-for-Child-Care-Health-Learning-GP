namespace Ajial.Application.DTOs.Clinic;

public class ClinicStatusChangeResponse
{
    public Guid ClinicId { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
}
