using Ajial.Application.DTOs.Auth;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Ajlal.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace Ajlal.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAuthService authService, ILogger<AuthController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    /// <summary>
    /// Register a new parent user
    /// </summary>
    /// <param name="request">Parent registration information</param>
    /// <returns>Registration result</returns>
    [HttpPost("register/parent")]
    [ProducesResponseType(typeof(ApiResponse<RegisterParentResponse>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<RegisterParentResponse>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<RegisterParentResponse>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> RegisterParent([FromBody] RegisterParentRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => e.ErrorMessage)
                    .ToList();

                return BadRequest(ApiResponse<RegisterParentResponse>.FailureResponse(
                    "خطأ في البيانات المدخلة", errors));
            }

            var result = await _authService.RegisterParentAsync(request);
            
            return CreatedAtAction(
                nameof(RegisterParent),
                ApiResponse<RegisterParentResponse>.SuccessResponse(
                    result, "تم إنشاء الحساب بنجاح"));
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Validation error during parent registration");
            return BadRequest(ApiResponse<RegisterParentResponse>.FailureResponse(
                ex.Message, new List<string> { ex.Message }));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error occurred during parent registration");
            return StatusCode(500, ApiResponse<RegisterParentResponse>.FailureResponse(
                "حدث خطأ أثناء إنشاء الحساب. يرجى المحاولة مرة أخرى"));
        }
    }
}