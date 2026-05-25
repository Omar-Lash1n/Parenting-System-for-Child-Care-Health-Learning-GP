namespace Ajial.Application.DTOs.Clinic;

public class UpdateClinicDetailsRequest
{
    public string? Name { get; set; }
    public int? GovernorateId { get; set; }
    public string? DistrictName { get; set; }
    public string? Address { get; set; }
    public string? Phone { get; set; }
}
