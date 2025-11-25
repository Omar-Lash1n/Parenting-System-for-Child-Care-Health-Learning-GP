using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.Child;

public class AddChildRequestDto
{
    [Required(ErrorMessage = "اسم الطفل مطلوب")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "اسم الطفل يجب أن يكون بين 2 و 100 حرف")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "تاريخ الميلاد مطلوب")]
    public DateTime BirthDate { get; set; }

    [Required(ErrorMessage = "الجنس مطلوب")]
    public string Gender { get; set; } = string.Empty;

    public IFormFile? ProfileImage { get; set; }
    
    public string? ChildLoginId { get; set; }
    
    public List<string>? FruitPasswordCodes { get; set; }
}