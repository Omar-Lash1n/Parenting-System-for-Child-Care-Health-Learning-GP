using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.DailyQuestion;
using Ajial.Application.Interfaces;
using Ajlal.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Authorize(Roles = "Parent")]
[Route("api/parent/daily-question")]
public class ParentDailyQuestionController : ControllerBase
{
    private readonly IDailyQuestionService _dailyQuestionService;
    private readonly IUnitOfWork _unitOfWork;

    public ParentDailyQuestionController(IDailyQuestionService dailyQuestionService, IUnitOfWork unitOfWork)
    {
        _dailyQuestionService = dailyQuestionService;
        _unitOfWork = unitOfWork;
    }

    [HttpGet("active")]
    [ProducesResponseType(typeof(ApiResponse<ActiveDailyQuestionDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetActiveQuestion()
    {
        var parentId = await GetParentIdFromTokenAsync();
        if (!parentId.HasValue)
            return UnauthorizedResponse<ActiveDailyQuestionDto>();

        var result = await _dailyQuestionService.GetActiveQuestionForParentAsync(parentId.Value);
        return ToActionResult(result);
    }

    [HttpPost("{questionId:guid}/answer")]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAnswerResultDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAnswerResultDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAnswerResultDto>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAnswerResultDto>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> SubmitAnswer(Guid questionId, [FromBody] SubmitDailyQuestionAnswerDto request)
    {
        var parentId = await GetParentIdFromTokenAsync();
        if (!parentId.HasValue)
            return UnauthorizedResponse<DailyQuestionAnswerResultDto>();

        if (!ModelState.IsValid)
            return BadRequest(ToModelStateFailure<DailyQuestionAnswerResultDto>());

        var result = await _dailyQuestionService.SubmitAnswerAsync(questionId, request, parentId.Value);
        return ToActionResult(result);
    }

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

        if (result.Message.Contains("حدث خطأ في الخادم"))
            return StatusCode(StatusCodes.Status500InternalServerError, result);

        return BadRequest(result);
    }
}
