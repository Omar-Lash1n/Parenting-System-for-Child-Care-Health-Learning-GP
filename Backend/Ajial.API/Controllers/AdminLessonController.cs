using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Lesson;
using Ajial.Application.Interfaces;
using Ajlal.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/admin/lessons")]
public class AdminLessonController : ControllerBase
{
    private readonly ILessonService _lessonService;
    private readonly IUnitOfWork _unitOfWork;

    public AdminLessonController(ILessonService lessonService, IUnitOfWork unitOfWork)
    {
        _lessonService = lessonService;
        _unitOfWork = unitOfWork;
    }

    // ── Categories ──────────────────────────────────────────────────────────

    [HttpPost("categories")]
    [ProducesResponseType(typeof(ApiResponse<LessonCategoryDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<LessonCategoryDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateCategory([FromBody] CreateLessonCategoryDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ToModelStateFailure<LessonCategoryDto>());

        var result = await _lessonService.CreateCategoryAsync(request);
        if (!result.Success)
            return ToActionResult(result);

        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpGet("categories")]
    [ProducesResponseType(typeof(ApiResponse<List<LessonCategoryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCategories([FromQuery] bool? isActive)
    {
        var result = await _lessonService.GetCategoriesAsync(isActive);
        return ToActionResult(result);
    }

    [HttpPut("categories/{categoryId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<LessonCategoryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<LessonCategoryDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<LessonCategoryDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateCategory(Guid categoryId, [FromBody] UpdateLessonCategoryDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ToModelStateFailure<LessonCategoryDto>());

        var result = await _lessonService.UpdateCategoryAsync(categoryId, request);
        return ToActionResult(result);
    }

    [HttpDelete("categories/{categoryId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> DeleteCategory(Guid categoryId)
    {
        var result = await _lessonService.DeleteCategoryAsync(categoryId);
        return ToActionResult(result);
    }

    // ── Lessons ─────────────────────────────────────────────────────────────

    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<LessonAdminDetailDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<LessonAdminDetailDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateLesson([FromBody] CreateLessonDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ToModelStateFailure<LessonAdminDetailDto>());

        var adminUserId = await GetAdminUserIdAsync();
        if (!adminUserId.HasValue)
            return ToActionResult(ApiResponse<LessonAdminDetailDto>.FailureResponse(
                "حدث خطأ في الخادم", new List<string> { "لا يوجد مستخدم متاح" }));

        var result = await _lessonService.CreateLessonAsync(request, adminUserId.Value);
        if (!result.Success)
            return ToActionResult(result);

        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<LessonAdminListDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetLessons([FromQuery] Guid? categoryId, [FromQuery] bool? isActive)
    {
        var result = await _lessonService.GetAllLessonsAdminAsync(categoryId, isActive);
        return ToActionResult(result);
    }

    [HttpGet("{lessonId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<LessonAdminDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<LessonAdminDetailDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetLesson(Guid lessonId)
    {
        var result = await _lessonService.GetLessonByIdAdminAsync(lessonId);
        return ToActionResult(result);
    }

    [HttpPut("{lessonId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<LessonAdminDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<LessonAdminDetailDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<LessonAdminDetailDto>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<LessonAdminDetailDto>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> UpdateLesson(Guid lessonId, [FromBody] UpdateLessonDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ToModelStateFailure<LessonAdminDetailDto>());

        var result = await _lessonService.UpdateLessonAsync(lessonId, request);
        return ToActionResult(result);
    }

    [HttpDelete("{lessonId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> DeleteLesson(Guid lessonId)
    {
        var result = await _lessonService.DeleteLessonAsync(lessonId);
        return ToActionResult(result);
    }

    [HttpPatch("{lessonId:guid}/activate")]
    [ProducesResponseType(typeof(ApiResponse<LessonAdminDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<LessonAdminDetailDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ActivateLesson(Guid lessonId)
    {
        var result = await _lessonService.ActivateLessonAsync(lessonId);
        return ToActionResult(result);
    }

    [HttpPatch("{lessonId:guid}/deactivate")]
    [ProducesResponseType(typeof(ApiResponse<LessonAdminDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<LessonAdminDetailDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeactivateLesson(Guid lessonId)
    {
        var result = await _lessonService.DeactivateLessonAsync(lessonId);
        return ToActionResult(result);
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private bool TryGetUserId(out Guid userId)
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
            ?? User.FindFirst("sub")?.Value;

        return Guid.TryParse(claimValue, out userId);
    }

    private async Task<Guid?> GetAdminUserIdAsync()
    {
        if (TryGetUserId(out var userId))
        {
            var tokenUser = await _unitOfWork.Users.GetByIdAsync(userId);
            if (tokenUser != null)
                return tokenUser.Id;
        }

        var firstUser = (await _unitOfWork.Users.GetAllAsync()).FirstOrDefault();
        return firstUser?.Id;
    }

    private ApiResponse<T> ToModelStateFailure<T>()
    {
        var errors = ModelState.Values
            .SelectMany(v => v.Errors)
            .Select(e => e.ErrorMessage)
            .ToList();

        return ApiResponse<T>.FailureResponse("بيانات غير صحيحة", errors);
    }

    private ObjectResult ToActionResult<T>(ApiResponse<T> result)
    {
        if (result.Success)
            return Ok(result);

        if (result.Message.Contains("غير موجود"))
            return NotFound(result);

        if (result.Message.Contains("لا يمكن"))
            return StatusCode(StatusCodes.Status409Conflict, result);

        if (result.Message.Contains("حدث خطأ في الخادم"))
            return StatusCode(StatusCodes.Status500InternalServerError, result);

        return BadRequest(result);
    }
}
