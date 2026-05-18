using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Ranking;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/ranking")]
public class RankingController : ControllerBase
{
    private readonly IRankingService _rankingService;

    public RankingController(IRankingService rankingService)
    {
        _rankingService = rankingService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PagedRankingDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<PagedRankingDto>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPublishedRanking(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _rankingService.GetPublishedRankingAsync(page, pageSize);
        if (!result.Success) return NotFound(result);
        return Ok(result);
    }

    [HttpGet("my-badges")]
    [ProducesResponseType(typeof(ApiResponse<List<ParentBadgeDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<ParentBadgeDto>>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMyBadges()
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        var result = await _rankingService.GetMyBadgesAsync(userId);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    private bool TryGetUserId(out Guid userId)
    {
        userId = Guid.Empty;
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return !string.IsNullOrEmpty(claim) && Guid.TryParse(claim, out userId);
    }
}
