using Ajial.Application.DTOs.Child;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ChildController : ControllerBase
{
    private readonly IChildService _childService;
    private readonly ILogger<ChildController> _logger;

    public ChildController(
        IChildService childService,
        ILogger<ChildController> logger)
    {
        _childService = childService;
        _logger = logger;
    }

    /// <summary>
    /// إضافة طفل جديد - Add new child
    /// </summary>
    /// <remarks>
    /// Steps:
    /// 1. الاسم الكامل (Full Name)
    /// 2. تاريخ الميلاد (Birth Date)
    /// 3. الجنس (Gender): ذكر أو أنثى
    /// 4. صورة الطفل (Optional Profile Image)
    /// 5. معرف تسجيل الدخول وكلمة المرور (Required only for ages 4-13)
    /// 
    /// For ages 4-13: Child must provide ChildLoginId and select 5 fruits for password
    /// For ages less than 4 or greater than 13: No login credentials required
    /// </remarks>
    [HttpPost("add")]
    [Authorize]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<AddChildResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<AddChildResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> AddChild([FromForm] AddChildRequestDto request)
    {
        try
        {
            // Get authenticated parent's user ID from JWT token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid parentUserId))
            {
                _logger.LogWarning("Unauthorized attempt to add child. Invalid user ID claim");
                return Unauthorized(ApiResponse<AddChildResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("Parent {ParentId} attempting to add child: {ChildName}", 
                parentUserId, request.FullName);

            var result = await _childService.AddChildAsync(request, parentUserId);

            if (!result.Success)
            {
                _logger.LogWarning("Failed to add child. Errors: {Errors}",
                    string.Join(", ", result.Errors));
                return BadRequest(result);
            }

            _logger.LogInformation("Child {ChildName} added successfully with ID: {ChildId}",
                request.FullName, result.Data?.ChildId);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in AddChild endpoint");
            return StatusCode(500, ApiResponse<AddChildResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// الحصول على قائمة الفواكه المتاحة - Get available fruits for password selection
    /// </summary>
    /// <remarks>
    /// Returns list of 10 fruits that can be used for creating child password (ages 4-13)
    /// Flutter will handle the fruit icons display
    /// </remarks>
    [HttpGet("fruits")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<List<FruitOptionDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAvailableFruits()
    {
        try
        {
            _logger.LogInformation("Fetching available fruits list");

            var result = await _childService.GetAvailableFruitsAsync();

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetAvailableFruits endpoint");
            return StatusCode(500, ApiResponse<List<FruitOptionDto>>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع" }
            ));
        }
    }

    /// <summary>
    /// التحقق من توفر معرف تسجيل الدخول - Check if child login ID is available
    /// </summary>
    /// <param name="childLoginId">معرف تسجيل الدخول المراد التحقق منه</param>
    [HttpGet("check-login-id/{childLoginId}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> CheckChildLoginIdAvailability(string childLoginId)
    {
        try
        {
            _logger.LogInformation("Checking availability of child login ID: {LoginId}", childLoginId);

            var result = await _childService.CheckChildLoginIdAvailabilityAsync(childLoginId);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in CheckChildLoginIdAvailability endpoint");
            return StatusCode(500, ApiResponse<bool>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع" }
            ));
        }
    }
}