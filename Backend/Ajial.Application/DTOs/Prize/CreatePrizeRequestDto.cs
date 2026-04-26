using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.Prize;

public class CreatePrizeRequestDto
{
    [Required(ErrorMessage = "عنوان الجائزة مطلوب")]
    public string Title { get; set; } = string.Empty;

    public IFormFile? PrizeImage { get; set; }

    public int RequiredStars { get; set; }

    public Guid ChildId { get; set; }

    [Required(ErrorMessage = "يجب اختيار مهمة واحدة على الأقل")]
    [MinLength(1, ErrorMessage = "يجب اختيار مهمة واحدة على الأقل")]
    public List<Guid> TaskIds { get; set; } = new();
}
