using Microsoft.AspNetCore.Http;

namespace Ajial.Application.DTOs.Prize;

public class UpdatePrizeRequestDto
{
    public string? Title { get; set; }
    public IFormFile? PrizeImage { get; set; }
    public string? ExistingImageUrl { get; set; }
    public string? RequiredStars { get; set; }
    public List<string>? TaskIds { get; set; }
}
