using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.DailyQuestion;
using Ajial.Application.Interfaces;
using Ajlal.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/admin/daily-questions")]
public class AdminDailyQuestionController : ControllerBase
{
    private readonly IDailyQuestionService _dailyQuestionService;
    private readonly IUnitOfWork _unitOfWork;

    public AdminDailyQuestionController(IDailyQuestionService dailyQuestionService, IUnitOfWork unitOfWork)
    {
        _dailyQuestionService = dailyQuestionService;
        _unitOfWork = unitOfWork;
    }

    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAdminDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAdminDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateQuestion([FromBody] CreateDailyQuestionDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ToModelStateFailure<DailyQuestionAdminDto>());

        var adminUserId = await GetTemporaryAdminUserIdAsync();
        if (!adminUserId.HasValue)
            return ToActionResult(ApiResponse<DailyQuestionAdminDto>.FailureResponse("حدث خطأ في الخادم", new List<string> { "لا يوجد مستخدم متاح لإنشاء السؤال" }));

        var result = await _dailyQuestionService.CreateQuestionAsync(request, adminUserId.Value);
        if (!result.Success)
            return ToActionResult(result);

        return CreatedAtAction(nameof(GetQuestion), new { questionId = result.Data!.Id }, result);
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<DailyQuestionAdminListDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetQuestions([FromQuery] bool? isActive)
    {
        var result = await _dailyQuestionService.GetAllQuestionsAsync(isActive);
        return ToActionResult(result);
    }

    [HttpGet("{questionId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAdminDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAdminDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetQuestion(Guid questionId)
    {
        var result = await _dailyQuestionService.GetQuestionByIdAsync(questionId);
        return ToActionResult(result);
    }

    [HttpPut("{questionId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAdminDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAdminDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAdminDto>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAdminDto>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> UpdateQuestion(Guid questionId, [FromBody] UpdateDailyQuestionDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ToModelStateFailure<DailyQuestionAdminDto>());

        var result = await _dailyQuestionService.UpdateQuestionAsync(questionId, request);
        return ToActionResult(result);
    }

    [HttpPatch("{questionId:guid}/activate")]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAdminDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAdminDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ActivateQuestion(Guid questionId)
    {
        var result = await _dailyQuestionService.ActivateQuestionAsync(questionId);
        return ToActionResult(result);
    }

    [HttpPatch("{questionId:guid}/deactivate")]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAdminDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<DailyQuestionAdminDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeactivateQuestion(Guid questionId)
    {
        var result = await _dailyQuestionService.DeactivateQuestionAsync(questionId);
        return ToActionResult(result);
    }

    [HttpPost("reset")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ResetQuestions()
    {
        var result = await _dailyQuestionService.ResetAllQuestionsAsync();
        return ToActionResult(result);
    }

    [HttpDelete("{questionId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> DeleteQuestion(Guid questionId)
    {
        var result = await _dailyQuestionService.DeleteQuestionAsync(questionId);
        return ToActionResult(result);
    }

    private bool TryGetUserId(out Guid userId)
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
            ?? User.FindFirst("sub")?.Value;

        return Guid.TryParse(claimValue, out userId);
    }

    private async Task<Guid?> GetTemporaryAdminUserIdAsync()
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

        if (result.Message.Contains("لا يمكن") || result.Message.Contains("لقد أجبت"))
            return StatusCode(StatusCodes.Status409Conflict, result);

        if (result.Message.Contains("حدث خطأ في الخادم"))
            return StatusCode(StatusCodes.Status500InternalServerError, result);

        return BadRequest(result);
    }
}
