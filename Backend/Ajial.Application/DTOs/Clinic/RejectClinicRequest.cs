using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.Clinic;

public class RejectClinicRequest
{
    [Required(ErrorMessage = "سبب الرفض مطلوب")]
    [MaxLength(1000)]
    public string Reason { get; set; } = string.Empty;
}
