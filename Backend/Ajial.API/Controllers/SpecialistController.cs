using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Specialist;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SpecialistController : ControllerBase
{
    private readonly ISpecialistService _specialistService;
    private readonly ILogger<SpecialistController> _logger;

    public SpecialistController(ISpecialistService specialistService, ILogger<SpecialistController> logger)
    {
        _specialistService = specialistService;
        _logger = logger;
    }

    /// <summary>
    /// Get all registered specialists — Admin endpoint
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<SpecialistDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<SpecialistDto>>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> GetAllSpecialists()
    {
        try
        {
            _logger.LogInformation("Fetching all registered specialists");

            var result = await _specialistService.GetAllSpecialistsAsync();

            if (!result.Success)
            {
                _logger.LogWarning("Failed to fetch specialists. Errors: {Errors}",
                    string.Join(", ", result.Errors));
                return StatusCode(500, result);
            }

            _logger.LogInformation("Fetched {Count} specialists", result.Data?.Count());
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetAllSpecialists endpoint");
            return StatusCode(500, ApiResponse<IEnumerable<SpecialistDto>>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// Approve or reject a pending specialist — Admin endpoint
    /// Status: 2 = Approved, 3 = Rejected
    /// </summary>
    [HttpPost("update-status")]
    [ProducesResponseType(typeof(ApiResponse<SpecialistDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<SpecialistDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<SpecialistDto>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<SpecialistDto>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> UpdateSpecialistStatus([FromBody] UpdateSpecialistStatusRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => e.ErrorMessage)
                    .ToList();

                return BadRequest(ApiResponse<SpecialistDto>.FailureResponse(
                    "خطأ في البيانات المدخلة", errors));
            }

            _logger.LogInformation(
                "Admin updating specialist {SpecialistId} status to {Status}",
                request.SpecialistId, request.Status);

            var result = await _specialistService.UpdateSpecialistStatusAsync(request);

            if (!result.Success)
            {
                // Return 404 if not found, 400 for other errors
                if (result.Errors.Any(e => e.Contains("غير موجود") || e.Contains("لم يتم العثور")))
                {
                    return NotFound(result);
                }

                return BadRequest(result);
            }

            _logger.LogInformation(
                "Specialist {SpecialistId} status updated to {Status}",
                request.SpecialistId, request.Status);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UpdateSpecialistStatus endpoint for specialist {SpecialistId}",
                request.SpecialistId);
            return StatusCode(500, ApiResponse<SpecialistDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }
}
