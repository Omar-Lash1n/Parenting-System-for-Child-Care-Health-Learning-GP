using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.Ranking;

public class PublishRankingRequestDto
{
    [Required(ErrorMessage = "اسم الموسم مطلوب")]
    [MaxLength(100, ErrorMessage = "اسم الموسم لا يتجاوز 100 حرف")]
    public string SeasonName { get; set; } = string.Empty;

    [Required(ErrorMessage = "تاريخ النشر التالي مطلوب")]
    public DateTime NextPublishAt { get; set; }
}
