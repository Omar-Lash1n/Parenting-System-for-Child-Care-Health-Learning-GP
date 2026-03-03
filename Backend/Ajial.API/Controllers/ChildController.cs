using Ajial.Application.DTOs.Child;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.VoiceNote;
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
    private readonly IVoiceNoteService _voiceNoteService;
    private readonly ILogger<ChildController> _logger;

    public ChildController(
        IChildService childService,
        IVoiceNoteService voiceNoteService,
        ILogger<ChildController> logger)
    {
        _childService = childService;
        _voiceNoteService = voiceNoteService;
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

    /// <summary>
    /// إنشاء حساب لطفل موجود أتم 4 سنوات - Create account for existing child (4+ years)
    /// </summary>
    /// <remarks>
    /// For children who were registered before turning 4 and now need a login account.
    /// The parent provides a unique 4-digit ChildLoginId and selects 5 fruits as password.
    /// 
    /// Validations:
    /// - Child must be 4+ years old
    /// - Child must not already have an account
    /// - ChildLoginId must be unique (4+ digits, numeric only)
    /// - Exactly 5 fruit codes required for password
    /// </remarks>
    [HttpPost("{childId}/create-account")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<ChildAccountDetailsDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ChildAccountDetailsDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> CreateChildAccount(Guid childId, [FromBody] CreateChildAccountDto request)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid parentUserId))
            {
                _logger.LogWarning("Unauthorized attempt to create child account. Invalid user ID claim");
                return Unauthorized(ApiResponse<ChildAccountDetailsDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("Parent {ParentId} attempting to create account for child {ChildId}",
                parentUserId, childId);

            var result = await _childService.CreateChildAccountAsync(childId, parentUserId, request);

            if (!result.Success)
            {
                _logger.LogWarning("Failed to create child account. Errors: {Errors}",
                    string.Join(", ", result.Errors));
                return BadRequest(result);
            }

            _logger.LogInformation("Account created successfully for child {ChildId} with LoginId: {LoginId}",
                childId, result.Data?.ChildLoginId);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in CreateChildAccount endpoint");
            return StatusCode(500, ApiResponse<ChildAccountDetailsDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// تسجيل ملاحظة صوتية - Upload voice note
    /// </summary>
    /// <remarks>
    /// Allows authenticated children to record and store voice notes.
    /// This serves as a psychological outlet for children to express their feelings.
    /// 
    /// Supported audio formats: .mp3, .wav, .m4a, .ogg, .webm
    /// Maximum file size: 10 MB
    /// </remarks>
    [HttpPost("voice-note")]
    [Authorize]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<UploadVoiceNoteResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<UploadVoiceNoteResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UploadVoiceNote([FromForm] UploadVoiceNoteRequestDto request)
    {
        try
        {
            // Get authenticated child's ID from JWT token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid childId))
            {
                _logger.LogWarning("Unauthorized attempt to upload voice note. Invalid user ID claim");
                return Unauthorized(ApiResponse<UploadVoiceNoteResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("Child {ChildId} attempting to upload voice note", childId);

            var result = await _voiceNoteService.UploadVoiceNoteAsync(request, childId);

            if (!result.Success)
            {
                _logger.LogWarning("Failed to upload voice note. Errors: {Errors}",
                    string.Join(", ", result.Errors));
                return BadRequest(result);
            }

            _logger.LogInformation("Voice note uploaded successfully with ID: {VoiceNoteId}",
                result.Data?.VoiceNoteId);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UploadVoiceNote endpoint");
            return StatusCode(500, ApiResponse<UploadVoiceNoteResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// جلب قائمة الملاحظات الصوتية - Get voice notes list
    /// </summary>
    /// <remarks>
    /// Returns all voice notes belonging to the authenticated child.
    /// Each child can only see their own voice notes.
    /// </remarks>
    [HttpGet("voice-notes")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<List<VoiceNoteItemDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<VoiceNoteItemDto>>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetVoiceNotes()
    {
        try
        {
            // Get authenticated child's ID from JWT token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid childId))
            {
                _logger.LogWarning("Unauthorized attempt to get voice notes. Invalid user ID claim");
                return Unauthorized(ApiResponse<List<VoiceNoteItemDto>>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("Child {ChildId} retrieving voice notes", childId);

            var result = await _voiceNoteService.GetVoiceNotesAsync(childId);

            if (!result.Success)
            {
                _logger.LogWarning("Failed to get voice notes. Errors: {Errors}",
                    string.Join(", ", result.Errors));
                return BadRequest(result);
            }

            _logger.LogInformation("Retrieved {Count} voice notes for child {ChildId}",
                result.Data?.Count ?? 0, childId);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetVoiceNotes endpoint");
            return StatusCode(500, ApiResponse<List<VoiceNoteItemDto>>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }
}