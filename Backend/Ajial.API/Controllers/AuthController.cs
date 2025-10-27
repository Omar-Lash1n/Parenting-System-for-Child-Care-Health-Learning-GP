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
    
    [HttpPost("login/parent")]
    [ProducesResponseType(typeof(ApiResponse<LoginResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<LoginResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<LoginResponseDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> LoginParent([FromBody] LoginRequestDto request)
    {
        try
        {
            // Log login attempt (don't log password!)
            _logger.LogInformation("Login attempt for username: {Username}", request.Username);

            var result = await _authService.LoginParentAsync(request);

            if (!result.Success)
            {
                _logger.LogWarning("Login failed for username: {Username}. Errors: {Errors}", 
                    request.Username, 
                    string.Join(", ", result.Errors));

                // Return 401 for authentication failures
                if (result.Errors.Any(e => e.Contains("اسم المستخدم أو كلمة المرور غير صحيحة")))
                {
                    return Unauthorized(result);
                }

                return BadRequest(result);
            }

            _logger.LogInformation("Login successful for username: {Username}, UserId: {UserId}", 
                request.Username, 
                result.Data?.UserId);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in LoginParent endpoint for username: {Username}", request.Username);
            return StatusCode(500, ApiResponse<LoginResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }
}