using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Ranking;
using Ajial.Application.Interfaces;
using Ajlal.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/admin/ranking")]
public class AdminRankingController : ControllerBase
{
    private readonly IRankingService _rankingService;

    public AdminRankingController(IRankingService rankingService)
    {
        _rankingService = rankingService;
    }

    [HttpGet("current")]
    [ProducesResponseType(typeof(ApiResponse<PagedAdminCurrentRankingDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCurrentRanking(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _rankingService.GetCurrentRankingAsync(page, pageSize);
        return ToActionResult(result);
    }

    [HttpPost("publish")]
    [ProducesResponseType(typeof(ApiResponse<PublishedRankingDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<PublishedRankingDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> PublishRanking([FromBody] PublishRankingRequestDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ToModelStateFailure<PublishedRankingDto>());

        var result = await _rankingService.PublishRankingAsync(request);
        return ToActionResult(result);
    }

    [HttpGet("history")]
    [ProducesResponseType(typeof(ApiResponse<List<AdminPublishedRankingDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetRankingHistory()
    {
        var result = await _rankingService.GetRankingHistoryAsync();
        return ToActionResult(result);
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
        if (result.Success) return Ok(result);
        if (result.Message.Contains("غير موجود")) return NotFound(result);
        if (result.Message.Contains("حدث خطأ في الخادم"))
            return StatusCode(StatusCodes.Status500InternalServerError, result);
        return BadRequest(result);
    }
}
