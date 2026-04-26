namespace Ajial.Application.DTOs.Prize;

public class GetPrizesForChildResponseDto
{
    public Guid ChildId { get; set; }
    public string ChildFullName { get; set; } = string.Empty;
    public int TotalStars { get; set; }
    public List<PrizeCardDto> Prizes { get; set; } = new();
}
