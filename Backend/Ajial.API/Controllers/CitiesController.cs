using Ajial.Application.DTOs.Common;
using Ajial.Infrastructure.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Ajial.API.Controllers;

/// <summary>
/// Controller for managing cities data
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class CitiesController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<CitiesController> _logger;

    public CitiesController(ApplicationDbContext context, ILogger<CitiesController> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// Get all active cities - الحصول على قائمة المدن
    /// </summary>
    /// <remarks>
    /// Returns a list of all active Egyptian cities with both English and Arabic names.
    /// 
    /// يرجع قائمة بجميع المدن المصرية النشطة مع الأسماء بالإنجليزية والعربية.
    /// 
    /// **Response includes:**
    /// - Id: City identifier
    /// - Name: City name in English
    /// - NameAr: City name in Arabic
    /// </remarks>
    /// <returns>List of active cities</returns>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<CityDto>>), 200)]
    public async Task<IActionResult> GetCities()
    {
        try
        {
            var cities = await _context.Cities
                .Where(c => c.IsActive)
                .OrderBy(c => c.Id)
                .Select(c => new CityDto
                {
                    Id = c.Id,
                    Name = c.Name,
                    NameAr = c.NameAr
                })
                .ToListAsync();

            return Ok(ApiResponse<List<CityDto>>.SuccessResponse(cities, "Cities retrieved successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving cities");
            return StatusCode(500, ApiResponse<List<CityDto>>.FailureResponse("An error occurred while retrieving cities"));
        }
    }
}

/// <summary>
/// City data transfer object
/// </summary>
public class CityDto
{
    /// <summary>
    /// City ID
    /// </summary>
    public int Id { get; set; }

    /// <summary>
    /// City name in English
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// City name in Arabic
    /// </summary>
    public string NameAr { get; set; } = string.Empty;
}
