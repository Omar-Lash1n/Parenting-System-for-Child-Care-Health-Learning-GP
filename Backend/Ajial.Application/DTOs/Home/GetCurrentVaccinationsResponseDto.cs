namespace Ajial.Application.DTOs.Home;

public class GetCurrentVaccinationsResponseDto
{
    public List<CurrentVaccinationCardDto> Vaccinations { get; set; } = new();
}
