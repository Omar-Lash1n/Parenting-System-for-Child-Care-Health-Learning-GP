using Ajial.Application.DTOs.ChildTask;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ChildTaskController : ControllerBase
{
    private readonly IChildTaskService _childTaskService;
    private readonly ILogger<ChildTaskController> _logger;

    public ChildTaskController(IChildTaskService childTaskService, ILogger<ChildTaskController> logger)
    {
        _childTaskService = childTaskService;
        _logger = logger;
    }

    private bool TryGetUserId(out Guid userId)
    {
        userId = Guid.Empty;
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return !string.IsNullOrEmpty(claim) && Guid.TryParse(claim, out userId);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // A. GET children list with eligibility
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// A. Get all children for a parent with their task eligibility status.
    /// Shows which children can receive tasks (must be 4+ years old).
    /// </summary>
    [HttpGet("parent/{parentId:guid}/children")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<GetChildrenForTasksResponseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetChildrenForTasks(Guid parentId)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        var result = await _childTaskService.GetChildrenForTasksAsync(parentId, userId);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // B. POST create task (multipart/form-data)
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// B. Create a child task — multipart/form-data.
    /// Required: title, selectedChildIds.
    /// Optional: taskImage (file), recording (file), stars, startDate, dueDate, isRecurring, repeatDays, repeatTime.
    /// </summary>
    [HttpPost]
    [Authorize]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<ChildTaskDetailDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateChildTask([FromForm] CreateChildTaskRequestDto request)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        if (!ModelState.IsValid)
            return BadRequest(ApiResponse<ChildTaskDetailDto>.FailureResponse("بيانات غير صحيحة",
                ModelState.Values.SelectMany(v => v.Errors).Select(e => e.ErrorMessage).ToList()));

        var result = await _childTaskService.CreateChildTaskAsync(request, userId);
        if (!result.Success) return BadRequest(result);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // C. GET all tasks for a specific child
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// C. Get all tasks assigned to a specific child.
    /// Returns two lists: pendingTasks and completedTasks with per-child completion status.
    /// </summary>
    [HttpGet("child/{childId:guid}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<GetChildTasksForChildResponseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetChildTasksByChild(Guid childId)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        var result = await _childTaskService.GetChildTasksByChildAsync(childId, userId);
        return result.Success ? Ok(result) : BadRequest(result);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // D. GET task details — requires childId to verify the child is assigned
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// D. Get full details of one task for a specific child.
    /// childId is required — returns 404 if the child is not assigned to this task.
    /// assignedChildren[] shows IsCompleted and CompletedAt for each child.
    /// </summary>
    [HttpGet("{taskId:guid}/child/{childId:guid}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<ChildTaskDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetChildTaskById(Guid taskId, Guid childId)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        var result = await _childTaskService.GetChildTaskByIdAsync(taskId, childId, userId);
        if (!result.Success) return NotFound(result);
        return Ok(result);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // E. PUT update task — requires childId to verify the child is assigned
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// E. Update a child task — multipart/form-data, ALL fields are optional (partial update).
    /// childId is required — returns 404 if the child is not assigned to this task.
    /// Only the fields you send will be updated; empty string = keep current value.
    /// Task details (title, image, recurrence) are shared and affect all assigned children.
    /// </summary>
    [HttpPut("{taskId:guid}/child/{childId:guid}")]
    [Authorize]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<ChildTaskDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateChildTask(Guid taskId, Guid childId, [FromForm] UpdateChildTaskRequestDto request)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        var result = await _childTaskService.UpdateChildTaskAsync(taskId, childId, request, userId);
        if (!result.Success) return result.Message?.Contains("غير موجود") == true ? NotFound(result) : BadRequest(result);
        return Ok(result);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // F. DELETE — remove one specific child from a task
    //    If last child → deletes the entire task + Azure blobs
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// F. Remove a specific child from a task.
    /// If this was the last assigned child — the entire task and its Azure blobs are deleted automatically.
    /// </summary>
    [HttpDelete("{taskId:guid}/child/{childId:guid}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> RemoveChildFromTask(Guid taskId, Guid childId)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        var result = await _childTaskService.RemoveChildFromTaskAsync(taskId, childId, userId);
        if (!result.Success) return NotFound(result);
        return Ok(result);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // G. PATCH — toggle completion for one specific child only
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// G. Toggle completion status for ONE specific child.
    /// Calling this again on an already-completed task will un-complete it (toggle).
    /// Other children assigned to the same task are NOT affected.
    /// </summary>
    [HttpPatch("{taskId:guid}/child/{childId:guid}/complete")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<ChildTaskDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ToggleChildTaskComplete(Guid taskId, Guid childId)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        var result = await _childTaskService.ToggleChildTaskCompleteAsync(taskId, childId, userId);
        if (!result.Success) return NotFound(result);
        return Ok(result);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // H. GET parent summary
    // ─────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// H. Get task summary for a parent — global totals + per-child breakdown of stars and task counts.
    /// </summary>
    [HttpGet("parent/{parentId:guid}/summary")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<ChildTaskSummaryDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetChildTaskSummary(Guid parentId)
    {
        if (!TryGetUserId(out Guid userId)) return Unauthorized();
        var result = await _childTaskService.GetChildTaskSummaryAsync(parentId, userId);
        return result.Success ? Ok(result) : BadRequest(result);
    }
}
