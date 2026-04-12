using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.HealthUnit;

namespace Ajial.Application.Interfaces;

/// <summary>
/// Service interface for health unit / vaccination place search operations
/// </summary>
public interface IHealthUnitService
{
    /// <summary>
    /// Search for health units with optional filters: keyword, type, city, and geo-proximity
    /// </summary>
    Task<ApiResponse<SearchHealthUnitsResponse>> SearchAsync(SearchHealthUnitsRequest request);

    /// <summary>
    /// Get detailed information about a single health unit
    /// </summary>
    Task<ApiResponse<HealthUnitDetailDto>> GetByIdAsync(int id, double? latitude = null, double? longitude = null);
}
