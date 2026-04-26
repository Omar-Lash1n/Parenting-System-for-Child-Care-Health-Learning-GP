using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Prize;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PrizeController : ControllerBase
{
    private readonly IPrizeService _prizeService;
    private readonly ILogger<PrizeController> _logger;

    public PrizeController(IPrizeService prizeService, ILogger<PrizeController> logger)
    {
        _prizeService = prizeService;
        _logger = logger;
    }

    private bool TryGetUserId(out Guid userId)
    {
        userId = Guid.Empty;
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return !string.IsNullOrEmpty(claim) && Guid.TryParse(claim, out userId);
    }

    [HttpPost]
    [Authorize]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<PrizeDetailDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> CreatePrize([FromForm] CreatePrizeRequestDto request)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        if (!ModelState.IsValid)
            return BadRequest(ApiResponse<PrizeDetailDto>.FailureResponse("بيانات غير صحيحة",
                ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList()));

        var result = await _prizeService.CreatePrizeAsync(request, userId);
        if (!result.Success) return BadRequest(result);

        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpGet("child/{childId:guid}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<GetPrizesForChildResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetPrizesForChild(Guid childId)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        var result = await _prizeService.GetPrizesForChildAsync(childId, userId);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    [HttpGet("{prizeId:guid}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<PrizeDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetPrizeById(Guid prizeId)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        var result = await _prizeService.GetPrizeByIdAsync(prizeId, userId);
        if (!result.Success) return NotFound(result);
        return Ok(result);
    }

    [HttpPut("{prizeId:guid}")]
    [Authorize]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<PrizeDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UpdatePrize(Guid prizeId, [FromForm] UpdatePrizeRequestDto request)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        var result = await _prizeService.UpdatePrizeAsync(prizeId, request, userId);
        if (!result.Success) return result.Message.Contains("غير موجودة") ? NotFound(result) : BadRequest(result);
        return Ok(result);
    }

    [HttpDelete("{prizeId:guid}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> DeletePrize(Guid prizeId)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        var result = await _prizeService.DeletePrizeAsync(prizeId, userId);
        if (!result.Success) return NotFound(result);
        return Ok(result);
    }

    [HttpPatch("{prizeId:guid}/deliver")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<PrizeDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> DeliverPrize(Guid prizeId)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        var result = await _prizeService.DeliverPrizeAsync(prizeId, userId);
        if (!result.Success) return result.Message.Contains("غير موجودة") ? NotFound(result) : BadRequest(result);
        return Ok(result);
    }

    [HttpGet("parent/{parentId:guid}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<GetPrizesForParentResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetPrizesForParent(Guid parentId)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        var result = await _prizeService.GetPrizesForParentAsync(parentId, userId);
        return result.Success ? Ok(result) : BadRequest(result);
    }
}
