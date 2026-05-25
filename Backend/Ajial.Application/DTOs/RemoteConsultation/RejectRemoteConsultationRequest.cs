using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.RemoteConsultation;

public class RejectRemoteConsultationRequest
{
    [Required(ErrorMessage = "سبب الرفض مطلوب")]
    [MaxLength(1000)]
    public string Reason { get; set; } = string.Empty;
}
