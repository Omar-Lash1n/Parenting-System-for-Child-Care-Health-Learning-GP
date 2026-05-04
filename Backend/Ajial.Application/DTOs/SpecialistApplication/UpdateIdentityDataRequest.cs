using Microsoft.AspNetCore.Http;

namespace Ajial.Application.DTOs.SpecialistApplication;

public class UpdateIdentityDataRequest
{
    public IFormFile? NationalIdFront { get; set; }
    public IFormFile? NationalIdBack { get; set; }
    public IFormFile? PersonalPhoto { get; set; }
}
