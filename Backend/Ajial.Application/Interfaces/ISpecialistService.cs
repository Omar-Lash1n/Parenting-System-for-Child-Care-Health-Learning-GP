using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Specialist;

namespace Ajial.Application.Interfaces;

public interface ISpecialistService
{
    /// <summary>
    /// Get all registered specialists with their full profile data
    /// </summary>
    Task<ApiResponse<IEnumerable<SpecialistDto>>> GetAllSpecialistsAsync();

    /// <summary>
    /// Approve or reject a pending specialist
    /// </summary>
    Task<ApiResponse<SpecialistDto>> UpdateSpecialistStatusAsync(UpdateSpecialistStatusRequest request);
}
