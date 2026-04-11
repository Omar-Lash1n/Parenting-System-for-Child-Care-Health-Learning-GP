using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Task;
using Ajial.Application.DTOs.TaskCategory;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TaskCategoryController : ControllerBase
{
    private readonly ITaskCategoryService _taskCategoryService;
    private readonly ILogger<TaskCategoryController> _logger;

    public TaskCategoryController(
        ITaskCategoryService taskCategoryService,
        ILogger<TaskCategoryController> logger)
    {
        _taskCategoryService = taskCategoryService;
        _logger = logger;
    }

    /// <summary>
    /// جلب تصنيفات المهام - Get task categories with task counts
    /// </summary>
    [HttpGet("parent/{parentId}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<GetCategoriesResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetCategories(Guid parentId)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                return Unauthorized(ApiResponse<GetCategoriesResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("User {UserId} requesting categories for parent {ParentId}", userId, parentId);

            var result = await _taskCategoryService.GetCategoriesAsync(parentId, userId);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetCategories endpoint");
            return StatusCode(500, ApiResponse<GetCategoriesResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// إضافة تصنيف جديد - Add new task category
    /// </summary>
    [HttpPost]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<TaskCategoryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<TaskCategoryDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> CreateCategory([FromBody] CreateCategoryRequestDto request)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                return Unauthorized(ApiResponse<TaskCategoryDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("User {UserId} creating category: {Name}", userId, request.Name);

            var result = await _taskCategoryService.CreateCategoryAsync(request, userId);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in CreateCategory endpoint");
            return StatusCode(500, ApiResponse<TaskCategoryDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// تحديث تصنيف - Update task category name
    /// </summary>
    [HttpPut("{categoryId}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<TaskCategoryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<TaskCategoryDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UpdateCategory(Guid categoryId, [FromBody] UpdateCategoryRequestDto request)
    {
        try
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                return Unauthorized(ApiResponse<TaskCategoryDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("User {UserId} updating category {CategoryId}", userId, categoryId);

            var result = await _taskCategoryService.UpdateCategoryAsync(categoryId, request, userId);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UpdateCategory endpoint");
            return StatusCode(500, ApiResponse<TaskCategoryDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// حذف تصنيف - Delete task category
    /// </summary>
    [HttpDelete("{categoryId}")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<bool>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> DeleteCategory(Guid categoryId)
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

            _logger.LogInformation("User {UserId} deleting category {CategoryId}", userId, categoryId);

            var result = await _taskCategoryService.DeleteCategoryAsync(categoryId, userId);

            if (!result.Success)
                return BadRequest(result);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in DeleteCategory endpoint");
            return StatusCode(500, ApiResponse<bool>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }
}
