using Ajial.Application.DTOs.HealthUnit;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

/// <summary>
/// أماكن التطعيم — Health Unit / Vaccination Place Search
/// Parent-facing read-only endpoints for finding nearby vaccination places
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class HealthUnitController : ControllerBase
{
    private readonly IHealthUnitService _healthUnitService;
    private readonly ILogger<HealthUnitController> _logger;

    public HealthUnitController(IHealthUnitService healthUnitService, ILogger<HealthUnitController> logger)
    {
        _healthUnitService = healthUnitService;
        _logger = logger;
    }

    /// <summary>
    /// البحث عن أماكن التطعيم القريبة
    /// Search for vaccination places / health units with optional geo-proximity, keyword, type, and city filters
    /// </summary>
    /// <param name="latitude">Parent's current latitude (خط العرض)</param>
    /// <param name="longitude">Parent's current longitude (خط الطول)</param>
    /// <param name="keyword">Search keyword (Arabic or English name)</param>
    /// <param name="type">Filter: HealthUnit, Hospital, VaccinationCenter, or null for all</param>
    /// <param name="cityId">Filter by city/governorate ID</param>
    /// <param name="radiusKm">Max search radius in km (default: 50)</param>
    /// <param name="page">Page number (default: 1)</param>
    /// <param name="pageSize">Results per page (default: 20, max: 50)</param>
    [HttpGet("search")]
    public async Task<IActionResult> Search(
        [FromQuery] double? latitude,
        [FromQuery] double? longitude,
        [FromQuery] string? keyword,
        [FromQuery] string? type,
        [FromQuery] int? cityId,
        [FromQuery] double radiusKm = 50,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var request = new SearchHealthUnitsRequest
        {
            Latitude = latitude,
            Longitude = longitude,
            Keyword = keyword,
            Type = type,
            CityId = cityId,
            RadiusKm = radiusKm,
            Page = page,
            PageSize = pageSize
        };

        var result = await _healthUnitService.SearchAsync(request);

        if (!result.Success)
            return BadRequest(result);

        return Ok(result);
    }

    /// <summary>
    /// تفاصيل مكان التطعيم
    /// Get detailed information about a specific health unit / vaccination place
    /// </summary>
    /// <param name="id">Health unit ID</param>
    /// <param name="latitude">Optional: parent's latitude for distance calculation</param>
    /// <param name="longitude">Optional: parent's longitude for distance calculation</param>
    [HttpGet("{id:int}")]
    public async Task<IActionResult> GetById(
        int id,
        [FromQuery] double? latitude,
        [FromQuery] double? longitude)
    {
        var result = await _healthUnitService.GetByIdAsync(id, latitude, longitude);

        if (!result.Success)
        {
            if (result.Message.Contains("غير موجود"))
                return NotFound(result);

            return BadRequest(result);
        }

        return Ok(result);
    }
}
