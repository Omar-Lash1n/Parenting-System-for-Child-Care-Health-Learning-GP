namespace Ajial.Application.DTOs.Prize;

public class GetPrizesForParentResponseDto
{
    public Guid ParentId { get; set; }
    public int TotalPrizes { get; set; }
    public List<PrizeDetailDto> Prizes { get; set; } = new();
}
