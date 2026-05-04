using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.SpecialistApplication;

public class RejectApplicationRequest
{
    [Required(ErrorMessage = "سبب الرفض مطلوب")]
    [StringLength(1000, ErrorMessage = "سبب الرفض لا يمكن أن يتجاوز 1000 حرف")]
    public string RejectionReason { get; set; } = string.Empty;
}
