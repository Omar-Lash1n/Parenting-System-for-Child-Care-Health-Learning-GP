using System.Security.Claims;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Parent;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ParentsController : ControllerBase
{
    private readonly IParentService _parentService;
    private readonly ILogger<ParentsController> _logger;

    public ParentsController(IParentService parentService, ILogger<ParentsController> logger)
    {
        _parentService = parentService;
        _logger = logger;
    }

    /// <summary>
    /// Get all parents data for analytics and Power BI
    /// </summary>
    /// <returns>Complete parent data including user info, demographics, and calculated metrics</returns>
    [HttpGet("analytics")]
    [ProducesResponseType(typeof(ApiResponse<List<ParentAnalyticsDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<List<ParentAnalyticsDto>>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> GetParentsAnalytics()
    {
        try
        {
            _logger.LogInformation("Fetching all parents data for analytics at {Time}", DateTime.UtcNow);

            var result = await _parentService.GetAllParentsForAnalyticsAsync();

            if (result.Success)
            {
                _logger.LogInformation("Successfully retrieved {Count} parent records for analytics",
                    result.Data?.Count ?? 0);
            }
            else
            {
                _logger.LogWarning("Failed to retrieve parents analytics data. Errors: {Errors}",
                    string.Join(", ", result.Errors));
            }

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetParentsAnalytics endpoint");
            return StatusCode(500, ApiResponse<List<ParentAnalyticsDto>>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع أثناء استرجاع البيانات" }
            ));
        }
    }

    /// <summary>
    /// Get analytics summary statistics
    /// </summary>
    /// <returns>Summary statistics for Power BI dashboards</returns>
    [HttpGet("analytics/summary")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAnalyticsSummary()
    {
        try
        {
            var result = await _parentService.GetAllParentsForAnalyticsAsync();

            if (!result.Success || result.Data == null)
            {
                return Ok(new
                {
                    success = false,
                    message = "No data available"
                });
            }

            var data = result.Data;

            var summary = new
            {
                success = true,
                message = "تم استرجاع الإحصائيات بنجاح",
                data = new
                {
                    totalParents = data.Count,
                    maleCount = data.Count(p => p.GenderCode == 1),
                    femaleCount = data.Count(p => p.GenderCode == 2),
                    averageAge = data.Any() ? (int)data.Average(p => p.Age) : 0,
                    ageGroups = data.GroupBy(p => p.AgeGroup)
                        .Select(g => new { ageGroup = g.Key, count = g.Count() })
                        .OrderBy(x => x.ageGroup),
                    citiesDistribution = data.GroupBy(p => p.CityName)
                        .Select(g => new { city = g.Key, count = g.Count() })
                        .OrderByDescending(x => x.count),
                    regionsDistribution = data.GroupBy(p => p.Region)
                        .Select(g => new { region = g.Key, count = g.Count() })
                        .OrderByDescending(x => x.count),
                    recentRegistrations = data.Where(p => p.AccountAgeInDays <= 30).Count(),
                    lastUpdated = DateTime.UtcNow
                }
            };

            return Ok(summary);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetAnalyticsSummary endpoint");
            return StatusCode(500, new
            {
                success = false,
                message = "حدث خطأ في الخادم"
            });
        }
    }

    /// <summary>
    /// Get logged-in parent's profile data (including children list)
    /// </summary>
    /// <remarks>
    /// Returns complete profile information including:
    /// - Profile image (null if not set - use default avatar)
    /// - Full name
    /// - Username
    /// - Email
    /// - Number of children
    /// - City (English and Arabic)
    /// - Date of birth
    /// - Gender
    /// - **Children list** (with name, image, age, and edit capability)
    /// 
    /// Each child includes:
    /// - Child ID (for future edit operations)
    /// - Full name
    /// - Profile image URL (nullable)
    /// - Age
    /// - Gender
    /// - Has account (true if ages 4-13 with login)
    /// - Child login ID
    /// - Is active
    /// 
    /// Requires authentication - returns data for the logged-in parent only. 
    /// </remarks>
    [HttpGet("profile")]
    [Authorize] // ✅ Requires JWT token
    [ProducesResponseType(typeof(ApiResponse<GetParentProfileResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<GetParentProfileResponseDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<GetParentProfileResponseDto>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<GetParentProfileResponseDto>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> GetParentProfile()
    {
        try
        {
            // Get user ID from JWT token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                _logger.LogWarning("Unauthorized profile access attempt - invalid user ID claim");
                return Unauthorized(ApiResponse<GetParentProfileResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول للوصول إلى الملف الشخصي" }
                ));
            }

            _logger.LogInformation("Parent profile requested by user ID: {UserId}", userId);

            var result = await _parentService.GetParentProfileAsync(userId);

            if (!result.Success)
            {
                _logger.LogWarning(
                    "Failed to retrieve profile for user {UserId}.  Errors: {Errors}",
                    userId,
                    string.Join(", ", result.Errors)
                );

                // Return 404 if parent not found
                if (result.Errors.Any(e => e.Contains("غير موجود")))
                {
                    return NotFound(result);
                }

                return BadRequest(result);
            }

            _logger.LogInformation(
                "Successfully returned profile for user {UserId}: {ParentName}",
                userId,
                result.Data?.FullName
            );

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in GetParentProfile endpoint");
            return StatusCode(500, ApiResponse<GetParentProfileResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع أثناء جلب الملف الشخصي" }
            ));
        }
    }

    /// <summary>
    /// Change parent's password from profile page
    /// </summary>
    /// <remarks>
    /// Allows logged-in parent to change their password. 
    /// 
    /// Requirements:
    /// - Must provide current password for verification
    /// - New password must meet strength requirements:
    ///   * At least 8 characters
    ///   * At least 1 uppercase letter
    ///   * At least 1 lowercase letter
    ///   * At least 1 digit
    ///   * At least 1 special character
    /// - New password must be different from current password
    /// - New password and confirm password must match
    /// 
    /// User stays logged in after password change (no need to re-login). 
    /// </remarks>
    /// <param name="request">Current password, new password, and confirmation</param>
    [HttpPut("change-password")]
    [Authorize] // Requires JWT token
    [ProducesResponseType(typeof(ApiResponse<ChangePasswordResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<ChangePasswordResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<ChangePasswordResponseDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<ChangePasswordResponseDto>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequestDto request)
    {
        try
        {
            // Get user ID from JWT token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                _logger.LogWarning("Unauthorized password change attempt - invalid user ID claim");
                return Unauthorized(ApiResponse<ChangePasswordResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول لتغيير كلمة المرور" }
                ));
            }

            _logger.LogInformation("Password change requested by user ID: {UserId}", userId);

            var result = await _parentService.ChangePasswordAsync(userId, request);

            if (!result.Success)
            {
                _logger.LogWarning(
                    "Password change failed for user {UserId}.  Errors: {Errors}",
                    userId,
                    string.Join(", ", result.Errors)
                );

                return BadRequest(result);
            }

            _logger.LogInformation("Password changed successfully for user {UserId}", userId);

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in ChangePassword endpoint");
            return StatusCode(500, ApiResponse<ChangePasswordResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع أثناء تغيير كلمة المرور" }
            ));
        }
    }

    /// <summary>
    /// Update parent profile (partial updates - only provided fields are updated)
    /// </summary>
    /// <remarks>
    /// Allows logged-in parent to update their profile information.
    /// 
    /// **All fields are optional** - provide only the fields you want to update. 
    /// 
    /// Updatable fields:
    /// - **fullName**: Full name (3-100 characters)
    /// - **username**: Username (3-50 characters, alphanumeric + underscore, must be unique)
    /// - **email**: Email address (valid email format, must be unique)
    /// - **cityId**: City ID (must exist in Cities table)
    /// - **dateOfBirth**: Date of birth (must be 18+ years old)
    /// - **role**: Parent role (1=Father/أب, 2=Mother/أم, 3=Educator/مربي)
    /// 
    /// Validation rules (same as registration):
    /// - Full name: 3-100 characters
    /// - Username: 3-50 characters, only letters, numbers, and underscore
    /// - Email: Valid format, unique across all users
    /// - Date of birth: Must be 18+ years old
    /// - City: Must exist and be active
    /// - Role: 1, 2, or 3
    /// 
    /// Examples:
    /// 
    /// **Update only name:**
    /// ```json
    /// { "fullName": "أحمد محمد الجديد" }
    /// ```
    /// 
    /// **Update multiple fields:**
    /// ```json
    /// {
    ///   "fullName": "أحمد محمد",
    ///   "email": "new_email@example.com",
    ///   "cityId": 2,
    ///   "role": 1
    /// }
    /// ```
    /// </remarks>
    [HttpPut("profile")]
    [Authorize] // Requires JWT token
    [ProducesResponseType(typeof(ApiResponse<UpdateParentProfileResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<UpdateParentProfileResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<UpdateParentProfileResponseDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<UpdateParentProfileResponseDto>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> UpdateParentProfile([FromBody] UpdateParentProfileRequestDto request)
    {
        try
        {
            // Get user ID from JWT token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                _logger.LogWarning("Unauthorized profile update attempt - invalid user ID claim");
                return Unauthorized(ApiResponse<UpdateParentProfileResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول لتحديث الملف الشخصي" }
                ));
            }

            _logger.LogInformation("Profile update requested by user ID: {UserId}", userId);

            var result = await _parentService.UpdateParentProfileAsync(userId, request);

            if (!result.Success)
            {
                _logger.LogWarning(
                    "Profile update failed for user {UserId}.  Errors: {Errors}",
                    userId,
                    string.Join(", ", result.Errors)
                );

                return BadRequest(result);
            }

            _logger.LogInformation(
                "Profile updated successfully for user {UserId}. Fields: {Fields}",
                userId,
                string.Join(", ", result.Data?.FieldsUpdated ?? new List<string>())
            );

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UpdateParentProfile endpoint");
            return StatusCode(500, ApiResponse<UpdateParentProfileResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع أثناء تحديث الملف الشخصي" }
            ));
        }
    }



    /// <summary>
    /// Upload or update parent profile image
    /// </summary>
    /// <remarks>
    /// Upload a new profile image or replace the existing one. 
    /// 
    /// **Image Requirements:**
    /// - Max size: 5MB
    /// - Allowed formats: JPG, JPEG, PNG
    /// - Recommended: Square image (500x500px or larger)
    /// 
    /// **Behavior:**
    /// - If parent has existing image, it will be deleted and replaced
    /// - If parent has no image, new image will be uploaded
    /// - Returns the new image URL
    /// 
    /// **Note:** Use Postman or client code for testing (Swagger file upload may have limitations)
    /// </remarks>
    /// <param name="image">Profile image file to upload</param>
    [HttpPost("profile/image")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<UploadParentImageResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<UploadParentImageResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<UploadParentImageResponseDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<UploadParentImageResponseDto>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> UploadProfileImage(IFormFile image)
    {
        try
        {
            // Get user ID from JWT token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                _logger.LogWarning("Unauthorized image upload attempt - invalid user ID claim");
                return Unauthorized(ApiResponse<UploadParentImageResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول لرفع الصورة" }
                ));
            }

            _logger.LogInformation("Profile image upload requested by user ID: {UserId}", userId);

            var result = await _parentService.UploadParentProfileImageAsync(userId, image);

            if (!result.Success)
            {
                _logger.LogWarning(
                    "Profile image upload failed for user {UserId}.  Errors: {Errors}",
                    userId,
                    string.Join(", ", result.Errors)
                );

                return BadRequest(result);
            }

            _logger.LogInformation(
                "Profile image uploaded successfully for user {UserId}. URL: {ImageUrl}",
                userId,
                result.Data?.ProfileImageUrl
            );

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UploadProfileImage endpoint");
            return StatusCode(500, ApiResponse<UploadParentImageResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع أثناء رفع الصورة" }
            ));
        }
    }

    /// <summary>
    /// حذف حساب ولي الأمر نهائياً - Delete parent account permanently
    /// </summary>
    /// <remarks>
    /// ⚠️ **تحذير: هذا الإجراء لا يمكن التراجع عنه!**
    /// 
    /// سيتم حذف:
    /// - حساب ولي الأمر
    /// - جميع بيانات الأطفال المرتبطة
    /// - صور الملفات الشخصية
    /// - رموز إعادة تعيين كلمة المرور
    /// 
    /// المتطلبات:
    /// - يجب إدخال كلمة المرور الحالية للتأكيد
    /// 
    /// **WARNING: This action cannot be undone!**
    /// 
    /// Will delete:
    /// - Parent account
    /// - All associated children data
    /// - Profile images
    /// - Password reset tokens
    /// 
    /// Requirements:
    /// - Must provide current password for confirmation
    /// </remarks>
    /// <param name="request">كلمة المرور للتأكيد - Password for confirmation</param>
    [HttpDelete("account")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<DeleteParentAccountResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<DeleteParentAccountResponseDto>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<DeleteParentAccountResponseDto>), StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<DeleteParentAccountResponseDto>), StatusCodes.Status500InternalServerError)]
    public async Task<IActionResult> DeleteParentAccount([FromBody] DeleteParentAccountRequestDto request)
    {
        try
        {
            // Get user ID from JWT token
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out Guid userId))
            {
                _logger.LogWarning("Unauthorized account deletion attempt - invalid user ID claim");
                return Unauthorized(ApiResponse<DeleteParentAccountResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "يجب تسجيل الدخول لحذف الحساب" }
                ));
            }

            _logger.LogInformation("Account deletion requested by user ID: {UserId}", userId);

            var result = await _parentService.DeleteParentAccountAsync(userId, request);

            if (!result.Success)
            {
                _logger.LogWarning(
                    "Account deletion failed for user {UserId}. Errors: {Errors}",
                    userId,
                    string.Join(", ", result.Errors)
                );

                return BadRequest(result);
            }

            _logger.LogInformation(
                "Account deleted successfully for user {UserId}. Children deleted: {ChildrenCount}",
                userId,
                result.Data?.ChildrenDeleted ?? 0
            );

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in DeleteParentAccount endpoint");
            return StatusCode(500, ApiResponse<DeleteParentAccountResponseDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { "حدث خطأ غير متوقع أثناء حذف الحساب" }
            ));
        }
    }
}