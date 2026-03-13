using Ajial.Application.DTOs.Auth;
using Ajial.Application.DTOs.Common;
using Ajlal.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

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

    /// <summary>
    /// Register a new specialist/doctor
    /// </summary>
    /// <param name="request">Specialist registration information with document images</param>
    /// <returns>Registration result</returns>
    [HttpPost("register/specialist")]
    [ProducesResponseType(typeof(ApiResponse<RegisterSpecialistResponse>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<RegisterSpecialistResponse>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<RegisterSpecialistResponse>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> RegisterSpecialist([FromForm] RegisterSpecialistRequest request)
    {
        try
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => e.ErrorMessage)
                    .ToList();

                return BadRequest(ApiResponse<RegisterSpecialistResponse>.FailureResponse(
                    "خطأ في البيانات المدخلة", errors));
            }

            var result = await _authService.RegisterSpecialistAsync(request);

            return CreatedAtAction(
                nameof(RegisterSpecialist),
                ApiResponse<RegisterSpecialistResponse>.SuccessResponse(
                    result, "تم إنشاء حساب الأخصائي بنجاح. في انتظار مراجعة الإدارة"));
        }
        catch (ArgumentException ex)
        {
            _logger.LogWarning(ex, "Validation error during specialist registration");
            return BadRequest(ApiResponse<RegisterSpecialistResponse>.FailureResponse(
                ex.Message, new List<string> { ex.Message }));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error occurred during specialist registration");
            return StatusCode(500, ApiResponse<RegisterSpecialistResponse>.FailureResponse(
                "حدث خطأ أثناء إنشاء حساب الأخصائي. يرجى المحاولة مرة أخرى"));
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


    /// <summary>
    /// تسجيل دخول الأخصائي/الطبيب - Specialist/Doctor Login
    /// </summary>
    [HttpPost("login/specialist")]
    [ProducesResponseType(typeof(ApiResponse<LoginSpecialistResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<LoginSpecialistResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<LoginSpecialistResponseDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> LoginSpecialist([FromBody] LoginRequestDto request)
    {
        try
        {
            _logger.LogInformation("Specialist login attempt for username: {Username}", request.Username);

            var result = await _authService.LoginSpecialistAsync(request);

            if (!result.Success)
            {
                _logger.LogWarning("Specialist login failed for username: {Username}. Errors: {Errors}",
                    request.Username,
                    string.Join(", ", result.Errors));

                if (result.Errors.Any(e => e.Contains("اسم المستخدم أو كلمة المرور غير صحيحة")))
                {
                    return Unauthorized(result);
                }

                return BadRequest(result);
            }

            _logger.LogInformation("Specialist login successful for username: {Username}, SpecialistId: {Id}",
                request.Username,
                result.Data?.SpecialistId);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in LoginSpecialist endpoint for username: {Username}", request.Username);
            return StatusCode(500, ApiResponse<LoginSpecialistResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// تسجيل دخول الطفل باستخدام معرف الدخول وكلمة المرور البصرية (5 فواكه)
    /// Child login using login ID and visual password (5 fruits)
    /// </summary>
    /// <param name="request">بيانات تسجيل الدخول</param>
    /// <returns>نتيجة تسجيل الدخول</returns>
    [HttpPost("login/child")]

    [ProducesResponseType(typeof(ApiResponse<LoginChildResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<LoginChildResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<LoginChildResponseDto>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> LoginChild([FromBody] LoginChildRequestDto request)
    {
        try
        {
            // Log login attempt (don't log password!)
            _logger.LogInformation("Child login attempt for login ID: {LoginId}", request.ChildLoginId);

            var result = await _authService.LoginChildAsync(request);

            if (!result.Success)
            {
                _logger.LogWarning("Child login failed for login ID: {LoginId}. Errors: {Errors}",
                    request.ChildLoginId,
                    string.Join(", ", result.Errors));

                // Return 401 for authentication failures
                if (result.Errors.Any(e => e.Contains("معرف الدخول أو كلمة السر غير صحيحة")))
                {
                    return Unauthorized(result);
                }

                return BadRequest(result);
            }

            _logger.LogInformation("Child login successful for login ID: {LoginId}, ChildId: {ChildId}",
                request.ChildLoginId,
                result.Data?.ChildId);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in LoginChild endpoint for login ID: {LoginId}", request.ChildLoginId);
            return StatusCode(500, ApiResponse<LoginChildResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    // Add these methods to AuthController

    /// <summary>
    /// طلب إعادة تعيين كلمة المرور (إرسال رمز عبر البريد الإلكتروني)
    /// </summary>
    [HttpPost("forgot-password")]
    [ProducesResponseType(typeof(ApiResponse<ForgotPasswordResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ForgotPasswordResponseDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequestDto request)
    {
        try
        {
            _logger.LogInformation("Password reset requested for email: {Email}", request.Email);

            var result = await _authService.ForgotPasswordAsync(request);

            if (!result.Success)
            {
                _logger.LogWarning("Password reset request failed for email: {Email}. Errors: {Errors}",
                    request.Email,
                    string.Join(", ", result.Errors));

                return BadRequest(result);
            }

            _logger.LogInformation("Password reset email sent to: {Email}", request.Email);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in ForgotPassword endpoint for email: {Email}", request.Email);
            return StatusCode(500, ApiResponse<ForgotPasswordResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// التحقق من صحة رمز OTP (6 أرقام) دون تغيير كلمة المرور
    /// </summary>
    [HttpPost("verify-otp")]
    [ProducesResponseType(typeof(ApiResponse<VerifyOtpResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<VerifyOtpResponseDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequestDto request)
    {
        try
        {
            _logger.LogInformation("OTP verification attempt for token: {Token}",
                request.Token?.Substring(0, 2) + "****"); // Log only first 2 digits for security

            var result = await _authService.VerifyOtpAsync(request);

            if (!result.Success)
            {
                _logger.LogWarning("OTP verification failed. Errors: {Errors}",
                    string.Join(", ", result.Errors));

                return BadRequest(result);
            }

            _logger.LogInformation("OTP verification successful");

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in VerifyOtp endpoint");
            return StatusCode(500, ApiResponse<VerifyOtpResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    //

    //test
    /// <summary>
    /// إعادة تعيين كلمة المرور باستخدام الرمز
    /// </summary>
    [HttpPost("reset-password")]
    [ProducesResponseType(typeof(ApiResponse<ResetPasswordResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ResetPasswordResponseDto>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequestDto request)
    {
        try
        {
            _logger.LogInformation("Password reset attempt with token");

            var result = await _authService.ResetPasswordAsync(request);

            if (!result.Success)
            {
                _logger.LogWarning("Password reset failed. Errors: {Errors}",
                    string.Join(", ", result.Errors));

                return BadRequest(result);
            }

            _logger.LogInformation("Password reset successful for user");

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in ResetPassword endpoint");
            return StatusCode(500, ApiResponse<ResetPasswordResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }

    /// <summary>
    /// تسجيل خروج الطفل - Child logout (sets IsActive to false)
    /// </summary>
    /// <remarks>
    /// Call this when the child logs out from the app.
    /// This clears the LastActivityAt timestamp so the parent sees IsActive = false (grey dot).
    /// Requires the child's JWT token.
    /// </remarks>
    [HttpPost("logout/child")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<string>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<string>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<string>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> LogoutChild()
    {
        try
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid childId))
            {
                _logger.LogWarning("Unauthorized child logout attempt - invalid user ID claim");
                return Unauthorized(ApiResponse<string>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول أولاً" }
                ));
            }

            _logger.LogInformation("Child logout requested for child ID: {ChildId}", childId);

            var result = await _authService.LogoutChildAsync(childId);

            if (!result.Success)
            {
                _logger.LogWarning("Child logout failed for child {ChildId}. Errors: {Errors}",
                    childId, string.Join(", ", result.Errors));
                return BadRequest(result);
            }

            _logger.LogInformation("Child {ChildId} logged out successfully", childId);
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in LogoutChild endpoint");
            return StatusCode(500, ApiResponse<string>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى لاحقاً" }
            ));
        }
    }
}