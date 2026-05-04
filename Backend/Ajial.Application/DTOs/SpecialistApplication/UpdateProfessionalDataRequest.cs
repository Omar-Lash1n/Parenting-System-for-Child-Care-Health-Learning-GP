using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace Ajial.Application.DTOs.SpecialistApplication;

public class UpdateProfessionalDataRequest
{
    public int? SpecialtyId { get; set; }

    [StringLength(50, ErrorMessage = "رقم الترخيص المهني لا يمكن أن يتجاوز 50 حرف")]
    public string? PracticeLicenseNumber { get; set; }

    public IFormFile? SpecializationCertificate { get; set; }
    public IFormFile? ProfessionalLicense { get; set; }
    public IFormFile? SyndicateCard { get; set; }
}
