using Ajial.Application.DTOs.ChildTask;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Prize;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Ajial.API.Controllers;

/// <summary>
/// Child-side home screen endpoints.
/// All routes require a valid Child JWT (role = "Child").
/// The childId is always derived from the token's Sub claim — never from the route.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Child")]
public class ChildHomeController : ControllerBase
{
    private readonly IChildHomeService _childHomeService;
    private readonly ILogger<ChildHomeController> _logger;

    public ChildHomeController(IChildHomeService childHomeService, ILogger<ChildHomeController> logger)
    {
        _childHomeService = childHomeService;
        _logger = logger;
    }

    private bool TryGetChildId(out Guid childId)
    {
        childId = Guid.Empty;
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return !string.IsNullOrEmpty(claim) && Guid.TryParse(claim, out childId);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // A. GET all tasks for the logged-in child
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Get all tasks assigned to the logged-in child.
    /// Returns pendingTasks and completedTasks with star totals.
    /// </summary>
    [HttpGet("tasks")]
    [ProducesResponseType(typeof(ApiResponse<GetChildTasksForChildResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMyTasks()
    {
        if (!TryGetChildId(out Guid childId)) return Unauthorized();
        var result = await _childHomeService.GetMyTasksAsync(childId);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // B. GET task details (includes RecordingUrl for audio playback)
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Get full details of a specific task assigned to the logged-in child.
    /// The response includes RecordingUrl — the parent voice message URL for audio playback.
    /// Returns 404 if the task does not belong to this child.
    /// </summary>
    [HttpGet("tasks/{taskId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<ChildTaskDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMyTaskDetails(Guid taskId)
    {
        if (!TryGetChildId(out Guid childId)) return Unauthorized();
        var result = await _childHomeService.GetMyTaskDetailsAsync(taskId, childId);
        if (!result.Success) return NotFound(result);
        return Ok(result);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // C. PATCH — mark task as complete (one-way, idempotent)
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Mark a task as completed by the logged-in child.
    /// One-way: once complete the child cannot undo (parent can toggle via the parent API).
    /// Idempotent: calling again on an already-completed task returns success.
    /// Completion is immediately visible on the parent side.
    /// </summary>
    [HttpPatch("tasks/{taskId:guid}/complete")]
    [ProducesResponseType(typeof(ApiResponse<ChildTaskDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> MarkTaskComplete(Guid taskId)
    {
        if (!TryGetChildId(out Guid childId)) return Unauthorized();
        var result = await _childHomeService.MarkTaskCompleteAsync(taskId, childId);
        if (!result.Success) return NotFound(result);
        return Ok(result);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // D. GET all prizes for the logged-in child
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Get all prizes assigned to the logged-in child.
    /// Each prize card shows current stars, required stars, remaining stars,
    /// task completion progress, and delivery status (Active / Ready / Delivered).
    /// </summary>
    [HttpGet("prizes")]
    [ProducesResponseType(typeof(ApiResponse<GetPrizesForChildResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetMyPrizes()
    {
        if (!TryGetChildId(out Guid childId)) return Unauthorized();
        var result = await _childHomeService.GetMyPrizesAsync(childId);
        return result.Success ? Ok(result) : BadRequest(result);
    }
}
