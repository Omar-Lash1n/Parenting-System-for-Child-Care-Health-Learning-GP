using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Task;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TaskController : ControllerBase
{
    private readonly ITaskService _taskService;
    private readonly ILogger<TaskController> _logger;

    public TaskController(
        ITaskService taskService,
        ILogger<TaskController> logger)
    {
        _taskService = taskService;
        _logger = logger;
    }

    /// <summary>
    /// جلب مهام ولي الأمر - Get all tasks for a parent
    /// </summary>
    [HttpGet("parent/{parentId}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<GetTasksResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetTasks(Guid parentId)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                return Unauthorized(ApiResponse<GetTasksResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("User {UserId} requesting tasks for parent {ParentId}", userId, parentId);

            var result = await _taskService.GetTasksAsync(parentId, userId);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetTasks endpoint");
            return StatusCode(500, ApiResponse<GetTasksResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// جلب تفاصيل مهمة - Get single task details (عرض التفاصيل)
    /// </summary>
    [HttpGet("{taskId}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<TaskCardDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<TaskCardDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetTask(Guid taskId)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                return Unauthorized(ApiResponse<TaskCardDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("User {UserId} requesting details for task {TaskId}", userId, taskId);

            var result = await _taskService.GetTaskByIdAsync(taskId, userId);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetTask endpoint");
            return StatusCode(500, ApiResponse<TaskCardDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// جلب المهام المنجزة - Get all completed tasks (المهام المنجزة)
    /// Returns tasks sorted by CompletedAt descending. Flutter groups them by date.
    /// </summary>
    [HttpGet("parent/{parentId}/done")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<GetDoneTasksResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetDoneTasks(Guid parentId)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                return Unauthorized(ApiResponse<GetDoneTasksResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("User {UserId} requesting done tasks for parent {ParentId}", userId, parentId);

            var result = await _taskService.GetDoneTasksAsync(parentId, userId);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetDoneTasks endpoint");
            return StatusCode(500, ApiResponse<GetDoneTasksResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// إضافة مهمة جديدة - Create a new task
    /// </summary>
    [HttpPost]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<TaskCardDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<TaskCardDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> CreateTask([FromBody] CreateTaskRequestDto request)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                return Unauthorized(ApiResponse<TaskCardDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("User {UserId} creating task: {Title}", userId, request.Title);

            var result = await _taskService.CreateTaskAsync(request, userId);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in CreateTask endpoint");
            return StatusCode(500, ApiResponse<TaskCardDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// تحديث مهمة - Update an existing task
    /// </summary>
    [HttpPut("{taskId}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<TaskCardDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<TaskCardDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UpdateTask(Guid taskId, [FromBody] UpdateTaskRequestDto request)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                return Unauthorized(ApiResponse<TaskCardDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("User {UserId} updating task {TaskId}", userId, taskId);

            var result = await _taskService.UpdateTaskAsync(taskId, request, userId);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UpdateTask endpoint");
            return StatusCode(500, ApiResponse<TaskCardDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// حذف مهمة - Delete a task
    /// </summary>
    [HttpDelete("{taskId}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> DeleteTask(Guid taskId)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                return Unauthorized(ApiResponse<bool>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("User {UserId} deleting task {TaskId}", userId, taskId);

            var result = await _taskService.DeleteTaskAsync(taskId, userId);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in DeleteTask endpoint");
            return StatusCode(500, ApiResponse<bool>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// تبديل حالة إنجاز المهمة - Toggle task completion status
    /// </summary>
    [HttpPatch("{taskId}/complete")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<TaskCardDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<TaskCardDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> ToggleComplete(Guid taskId)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                return Unauthorized(ApiResponse<TaskCardDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("User {UserId} toggling completion for task {TaskId}", userId, taskId);

            var result = await _taskService.ToggleCompleteAsync(taskId, userId);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in ToggleComplete endpoint");
            return StatusCode(500, ApiResponse<TaskCardDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }
}
