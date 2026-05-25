namespace Ajial.Application.DTOs.Clinic;

public class UpdateClinicHoursRequest
{
    public string? WorkingHoursJson { get; set; }
    public decimal? ExaminationPrice { get; set; }
    public decimal? ConsultationPrice { get; set; }
}
