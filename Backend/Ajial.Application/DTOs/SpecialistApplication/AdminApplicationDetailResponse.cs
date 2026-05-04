namespace Ajial.Application.DTOs.SpecialistApplication;

public class AdminApplicationDetailResponse : ApplicationDetailsResponse
{
    public string SpecialistName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public List<StatusHistoryDto> StatusHistory { get; set; } = new();
}
