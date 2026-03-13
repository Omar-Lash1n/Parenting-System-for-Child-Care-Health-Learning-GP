using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.Specialist;

public class UpdateSpecialistStatusRequest
{
    [Required(ErrorMessage = "معرف الأخصائي مطلوب")]
    public Guid SpecialistId { get; set; }

    /// <summary>
    /// 2 = Approved, 3 = Rejected
    /// </summary>
    [Required(ErrorMessage = "الحالة مطلوبة")]
    [Range(2, 3, ErrorMessage = "الحالة يجب أن تكون 2 (موافقة) أو 3 (رفض)")]
    public int Status { get; set; }

    public string? RejectionReason { get; set; }
}
