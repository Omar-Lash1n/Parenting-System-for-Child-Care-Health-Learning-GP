using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Lesson;
using Ajial.Application.Interfaces;
using Ajlal.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Authorize(Roles = "Parent")]
[Route("api/parent/lessons")]
public class ParentLessonController : ControllerBase
{
    private readonly ILessonService _lessonService;
    private readonly IUnitOfWork _unitOfWork;

    public ParentLessonController(ILessonService lessonService, IUnitOfWork unitOfWork)
    {
        _lessonService = lessonService;
        _unitOfWork = unitOfWork;
    }

    [HttpGet("categories")]
    [ProducesResponseType(typeof(ApiResponse<List<LessonCategoryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCategories()
    {
        var result = await _lessonService.GetActiveCategoriesAsync();
        return ToActionResult(result);
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<LessonCardDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetLessons(
        [FromQuery] Guid? categoryId,
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var parentId = await GetParentIdFromTokenAsync();
        if (!parentId.HasValue)
            return UnauthorizedResponse<List<LessonCardDto>>();

        var query = new GetLessonsQueryDto
        {
            CategoryId = categoryId,
            Search = search,
            Page = page < 1 ? 1 : page,
            PageSize = pageSize > 50 ? 50 : pageSize < 1 ? 20 : pageSize
        };

        var result = await _lessonService.GetLessonsForParentAsync(query, parentId.Value);
        return ToActionResult(result);
    }

    [HttpGet("{lessonId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<LessonDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<LessonDetailDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetLesson(Guid lessonId)
    {
        var parentId = await GetParentIdFromTokenAsync();
        if (!parentId.HasValue)
            return UnauthorizedResponse<LessonDetailDto>();

        var result = await _lessonService.GetLessonDetailForParentAsync(lessonId, parentId.Value);
        return ToActionResult(result);
    }

    [HttpPost("{lessonId:guid}/mark-read")]
    [ProducesResponseType(typeof(ApiResponse<MarkLessonReadResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<MarkLessonReadResponseDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> MarkRead(Guid lessonId)
    {
        var parentId = await GetParentIdFromTokenAsync();
        if (!parentId.HasValue)
            return UnauthorizedResponse<MarkLessonReadResponseDto>();

        var result = await _lessonService.MarkLessonReadAsync(lessonId, parentId.Value);
        return ToActionResult(result);
    }

    [HttpPost("{lessonId:guid}/questions/{questionId:guid}/answer")]
    [ProducesResponseType(typeof(ApiResponse<LessonAnswerResultDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<LessonAnswerResultDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<LessonAnswerResultDto>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<LessonAnswerResultDto>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> SubmitAnswer(
        Guid lessonId, Guid questionId, [FromBody] SubmitLessonAnswerDto request)
    {
        var parentId = await GetParentIdFromTokenAsync();
        if (!parentId.HasValue)
            return UnauthorizedResponse<LessonAnswerResultDto>();

        if (!ModelState.IsValid)
            return BadRequest(ToModelStateFailure<LessonAnswerResultDto>());

        var result = await _lessonService.SubmitAnswerAsync(lessonId, questionId, request, parentId.Value);
        return ToActionResult(result);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private async Task<Guid?> GetParentIdFromTokenAsync()
    {
        if (!TryGetUserId(out var userId))
            return null;

        var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == userId);
        return parent?.Id;
    }

    private bool TryGetUserId(out Guid userId)
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
            ?? User.FindFirst("sub")?.Value;

        return Guid.TryParse(claimValue, out userId);
    }

    private ObjectResult UnauthorizedResponse<T>()
    {
        return StatusCode(StatusCodes.Status401Unauthorized,
            ApiResponse<T>.FailureResponse("غير مصرح", new List<string> { "غير مصرح" }));
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

        if (result.Message.Contains("لقد أجبت"))
            return StatusCode(StatusCodes.Status409Conflict, result);

        if (result.Message.Contains("يجب قراءة الدرس"))
            return StatusCode(StatusCodes.Status403Forbidden, result);

        if (result.Message.Contains("حدث خطأ في الخادم"))
            return StatusCode(StatusCodes.Status500InternalServerError, result);

        return BadRequest(result);
    }
}
