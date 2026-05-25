using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Parent;
using Ajial.Application.DTOs.Validators;
using Ajial.Application.Interfaces;
using Ajial.Application.Validators;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Ajial.Application.Service;

public class ParentService : IParentService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<ParentService> _logger;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IImageService _imageService;
    private readonly IEmailService _emailService;
    private const string BaseApiUrl = "https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net";

    public ParentService(
        IUnitOfWork unitOfWork,
        ILogger<ParentService> logger,
        IPasswordHasher passwordHasher,
        IImageService imageService,
        IEmailService emailService)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
        _passwordHasher = passwordHasher;
        _imageService = imageService;
        _emailService = emailService;
    }

    public async Task<ApiResponse<List<ParentAnalyticsDto>>> GetAllParentsForAnalyticsAsync()
    {
        try
        {
            // Get all parents with related data using Include
            var parents = await _unitOfWork.Parents
                .GetAllAsync(
                    include: query => query
                        .Include(p => p.User)
                        .Include(p => p.City)
                );

            if (parents == null || !parents.Any())
            {
                return ApiResponse<List<ParentAnalyticsDto>>.SuccessResponse(
                    new List<ParentAnalyticsDto>(),
                    "لا توجد بيانات"
                );
            }

            // Map to DTOs with calculated fields
            var analyticsData = parents.Select(parent => new ParentAnalyticsDto
            {
                // User Information
                UserId = parent.User.Id,
                FullName = parent.User.FullName,
                Username = parent.User.Username,
                Email = parent.User.Email,
                UserCreatedAt = parent.User.CreatedAt,
                UserUpdatedAt = parent.User.UpdatedAt,

                // Parent Information
                ParentId = parent.Id,
                DateOfBirth = parent.DateOfBirth,
                Age = CalculateAge(parent.DateOfBirth),
                Gender = parent.Gender == ParentGender.Father ? "Father" : "Mother",  // ✅ Fixed: Use ParentGender enum
                GenderCode = (int)parent.Gender,

                // City Information
                CityId = parent.City.Id,
                CityName = parent.City.Name,
                CityNameAr = parent.City.NameAr,
                CityIsActive = parent.City.IsActive,

                // Calculated Fields
                AccountAgeInDays = (DateTime.UtcNow - parent.User.CreatedAt).Days,
                AgeGroup = GetAgeGroup(CalculateAge(parent.DateOfBirth)),
                Region = GetRegion(parent.City.Name)
            }).ToList();

            return ApiResponse<List<ParentAnalyticsDto>>.SuccessResponse(
                analyticsData,
                $"تم استرجاع بيانات {analyticsData.Count} ولي أمر بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<List<ParentAnalyticsDto>>.FailureResponse(
                "حدث خطأ أثناء استرجاع البيانات",
                new List<string> { ex.Message }
            );
        }
    }

    // Helper method to calculate age
    private int CalculateAge(DateTime dateOfBirth)
    {
        var today = DateTime.UtcNow;
        var age = today.Year - dateOfBirth.Year;

        if (dateOfBirth.Date > today.AddYears(-age))
        {
            age--;
        }

        return age;
    }

    // Helper method to categorize age groups
    private string GetAgeGroup(int age)
    {
        return age switch
        {
            >= 18 and <= 25 => "18-25",
            >= 26 and <= 35 => "26-35",
            >= 36 and <= 45 => "36-45",
            >= 46 and <= 55 => "46-55",
            _ => "56+"
        };
    }

    // Helper method to get region based on city
    private string GetRegion(string cityName)
    {
        return cityName switch
        {
            "Cairo" => "Greater Cairo",
            "Giza" => "Greater Cairo",
            "Shubra El Kheima" => "Greater Cairo",
            "Alexandria" => "Mediterranean",
            "Port Said" => "Canal Zone",
            _ => "Other"
        };
    }

    /// <summary>
    /// Get parent profile data for the logged-in parent (including children)
    /// </summary>
    public async Task<ApiResponse<GetParentProfileResponseDto>> GetParentProfileAsync(Guid userId)
    {
        try
        {
            _logger.LogInformation("Fetching profile for user ID: {UserId}", userId);

            // Get parent with related data (including children)
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(
                predicate: p => p.UserId == userId,
                includeProperties: "User,City,Children"
            );

            if (parent == null)
            {
                _logger.LogWarning("Parent not found for user ID: {UserId}", userId);
                return ApiResponse<GetParentProfileResponseDto>.FailureResponse(
                    "الملف الشخصي غير موجود",
                    new List<string> { "لم يتم العثور على بيانات الملف الشخصي" }
                );
            }

            // Check if user is active
            if (!parent.User.IsActive)
            {
                _logger.LogWarning("Inactive user attempted to access profile: {UserId}", userId);
                return ApiResponse<GetParentProfileResponseDto>.FailureResponse(
                    "الحساب غير نشط",
                    new List<string> { "هذا الحساب غير نشط" }
                );
            }

            // Map children to DTOs
            var childrenDtos = parent.Children?
                .OrderByDescending(c => c.CreatedAt) // Newest first
                .Select(child => new ChildBasicInfoDto
                {
                    ChildId = child.Id,
                    FullName = child.FullName,
                    ProfileImageUrl = child.ProfileImageUrl,
                    Age = child.Age,
                    Gender = child.Gender,
                    HasAccount = !string.IsNullOrEmpty(child.ChildLoginId),
                    ChildLoginId = child.ChildLoginId,
                    IsActive = child.IsActive
                })
                .ToList() ?? new List<ChildBasicInfoDto>();

            // Map to DTO
            var profileDto = new GetParentProfileResponseDto
            {
                ParentId = parent.Id,
                UserId = parent.UserId,
                ProfileImageUrl = parent.ProfileImageUrl,
                FullName = parent.User.FullName,
                Username = parent.User.Username,
                Email = parent.User.Email,
                NumberOfChildren = childrenDtos.Count,
                CityName = parent.City.Name,
                CityNameAr = parent.City.NameAr,
                DateOfBirth = parent.DateOfBirth,
                Gender = parent.Gender.ToString(),
                RoleCode = (int)parent.Gender,
                Role = GetRoleDisplayName(parent.Gender),
                IsEmailVerified = parent.User.IsEmailVerified,
                EmailVerificationStatus = parent.User.IsEmailVerified ? "مؤكد" : "غير مؤكد",
                Children = childrenDtos // ✅ NEW: Include children list
            };

            _logger.LogInformation(
                "Successfully retrieved profile for user {UserId}.  Parent: {ParentName}, Children: {ChildCount}",
                userId, profileDto.FullName, childrenDtos.Count
            );

            return ApiResponse<GetParentProfileResponseDto>.SuccessResponse(
                profileDto,
                "تم جلب بيانات الملف الشخصي بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching profile for user ID: {UserId}", userId);
            return ApiResponse<GetParentProfileResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب بيانات الملف الشخصي",
                new List<string> { ex.Message }
            );
        }
    }


    /// <summary>
    /// Change parent's password from profile page
    /// </summary>
    public async Task<ApiResponse<ChangePasswordResponseDto>> ChangePasswordAsync(
        Guid userId,
        ChangePasswordRequestDto request)
    {
        try
        {
            _logger.LogInformation("Password change requested for user ID: {UserId}", userId);

            // Step 1: Validate input
            var validator = new ChangePasswordRequestValidator();
            var (isValid, errors) = validator.Validate(request);

            if (!isValid)
            {
                _logger.LogWarning(
                    "Password change validation failed for user {UserId}. Errors: {Errors}",
                    userId,
                    string.Join(", ", errors)
                );

                return ApiResponse<ChangePasswordResponseDto>.FailureResponse(
                    "فشل في تغيير كلمة المرور",
                    errors
                );
            }

            // Step 2: Get user
            var user = await _unitOfWork.Users.GetFirstOrDefaultAsync(
                predicate: u => u.Id == userId
            );

            if (user == null)
            {
                _logger.LogWarning("User not found for password change: {UserId}", userId);
                return ApiResponse<ChangePasswordResponseDto>.FailureResponse(
                    "المستخدم غير موجود",
                    new List<string> { "لم يتم العثور على المستخدم" }
                );
            }

            // Step 3: Verify user is a parent
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(
                predicate: p => p.UserId == userId
            );

            if (parent == null)
            {
                _logger.LogWarning("User {UserId} is not a parent", userId);
                return ApiResponse<ChangePasswordResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "هذه الوظيفة متاحة فقط لأولياء الأمور" }
                );
            }

            // Step 4: Check if user is active
            if (!user.IsActive)
            {
                _logger.LogWarning("Inactive user attempted password change: {UserId}", userId);
                return ApiResponse<ChangePasswordResponseDto>.FailureResponse(
                    "الحساب غير نشط",
                    new List<string> { "لا يمكن تغيير كلمة المرور لحساب غير نشط" }
                );
            }

            // Step 5: Verify current password
            bool isCurrentPasswordValid = _passwordHasher.VerifyPassword(
                request.CurrentPassword,
                user.PasswordHash
            );

            if (!isCurrentPasswordValid)
            {
                _logger.LogWarning("Invalid current password for user {UserId}", userId);
                return ApiResponse<ChangePasswordResponseDto>.FailureResponse(
                    "كلمة المرور الحالية غير صحيحة",
                    new List<string> { "كلمة المرور الحالية التي أدخلتها غير صحيحة" }
                );
            }

            // Step 6: Hash new password
            string newPasswordHash = _passwordHasher.HashPassword(request.NewPassword);

            // Step 7: Update password
            user.PasswordHash = newPasswordHash;
            user.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Users.UpdateAsync(user);

            // Step 8: Save changes
            await _unitOfWork.SaveChangesAsync();

            _logger.LogInformation(
                "Password changed successfully for user {UserId}: {Username}",
                userId,
                user.Username
            );

            // Step 9: Return success response
            var response = new ChangePasswordResponseDto
            {
                Message = "تم تغيير كلمة المرور بنجاح",
                ChangedAt = DateTime.UtcNow,
                StayLoggedIn = true // User stays logged in
            };

            return ApiResponse<ChangePasswordResponseDto>.SuccessResponse(
                response,
                "تم تغيير كلمة المرور بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error changing password for user ID: {UserId}", userId);
            return ApiResponse<ChangePasswordResponseDto>.FailureResponse(
                "حدث خطأ أثناء تغيير كلمة المرور",
                new List<string> { "حدث خطأ غير متوقع.  يرجى المحاولة لاحقاً" }
            );
        }
    }
    /// <summary>
    /// Update parent profile with partial updates (only provided fields are updated)
    /// </summary>
    public async Task<ApiResponse<UpdateParentProfileResponseDto>> UpdateParentProfileAsync(
        Guid userId,
        UpdateParentProfileRequestDto request)
    {
        try
        {
            _logger.LogInformation("Profile update requested for user ID: {UserId}", userId);

            // Step 1: Validate input
            var validator = new UpdateParentProfileRequestValidator();
            var (isValid, errors) = validator.Validate(request);

            if (!isValid)
            {
                _logger.LogWarning(
                    "Profile update validation failed for user {UserId}. Errors: {Errors}",
                    userId,
                    string.Join(", ", errors)
                );

                return ApiResponse<UpdateParentProfileResponseDto>.FailureResponse(
                    "فشل في تحديث البيانات",
                    errors
                );
            }

            // Step 2: Get user and parent
            var user = await _unitOfWork.Users.GetFirstOrDefaultAsync(
                predicate: u => u.Id == userId
            );

            if (user == null)
            {
                _logger.LogWarning("User not found for profile update: {UserId}", userId);
                return ApiResponse<UpdateParentProfileResponseDto>.FailureResponse(
                    "المستخدم غير موجود",
                    new List<string> { "لم يتم العثور على المستخدم" }
                );
            }

            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(
                predicate: p => p.UserId == userId,
                includeProperties: "City"
            );

            if (parent == null)
            {
                _logger.LogWarning("Parent not found for user {UserId}", userId);
                return ApiResponse<UpdateParentProfileResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "هذه الوظيفة متاحة فقط لأولياء الأمور" }
                );
            }

            // Step 3: Check if user is active
            if (!user.IsActive)
            {
                _logger.LogWarning("Inactive user attempted profile update: {UserId}", userId);
                return ApiResponse<UpdateParentProfileResponseDto>.FailureResponse(
                    "الحساب غير نشط",
                    new List<string> { "لا يمكن تحديث حساب غير نشط" }
                );
            }

            var fieldsUpdated = new List<string>();

            // Step 4: Update Full Name (if provided)
            if (request.FullName != null && request.FullName.Trim() != user.FullName)
            {
                user.FullName = request.FullName.Trim();
                fieldsUpdated.Add("fullName");
                _logger.LogInformation("Updating full name for user {UserId}", userId);
            }

            // Step 5: Update Username (if provided)
            if (request.Username != null && request.Username.Trim() != user.Username)
            {
                var trimmedUsername = request.Username.Trim();

                // Check uniqueness
                var usernameExists = await _unitOfWork.Users.GetFirstOrDefaultAsync(
                    predicate: u => u.Username == trimmedUsername && u.Id != userId
                );

                if (usernameExists != null)
                {
                    return ApiResponse<UpdateParentProfileResponseDto>.FailureResponse(
                        "اسم المستخدم موجود بالفعل",
                        new List<string> { "اسم المستخدم هذا مستخدم من قبل شخص آخر" }
                    );
                }

                user.Username = trimmedUsername;
                fieldsUpdated.Add("username");
                _logger.LogInformation("Updating username for user {UserId}", userId);
            }

            // Step 6: Update Email (if provided)
            if (request.Email != null && request.Email.Trim().ToLower() != user.Email.ToLower())
            {
                var trimmedEmail = request.Email.Trim().ToLower();

                // Check uniqueness
                var emailExists = await _unitOfWork.Users.GetFirstOrDefaultAsync(
                    predicate: u => u.Email == trimmedEmail && u.Id != userId
                );

                if (emailExists != null)
                {
                    return ApiResponse<UpdateParentProfileResponseDto>.FailureResponse(
                        "البريد الإلكتروني موجود بالفعل",
                        new List<string> { "البريد الإلكتروني هذا مستخدم من قبل شخص آخر" }
                    );
                }

                user.Email = trimmedEmail;

                // Reset email verification status - user must verify new email
                if (user.IsEmailVerified)
                {
                    user.IsEmailVerified = false;
                    user.EmailVerifiedAt = null;
                    _logger.LogInformation("Email verification reset for user {UserId} due to email change", userId);
                }

                fieldsUpdated.Add("email");
                _logger.LogInformation("Updating email for user {UserId}", userId);
            }

            // Step 7: Update City (if provided)
            if (request.CityId.HasValue && request.CityId.Value != parent.CityId)
            {
                // Verify city exists
                var cityExists = await _unitOfWork.Cities.GetFirstOrDefaultAsync(
                    predicate: c => c.Id == request.CityId.Value && c.IsActive
                );

                if (cityExists == null)
                {
                    return ApiResponse<UpdateParentProfileResponseDto>.FailureResponse(
                        "المدينة غير موجودة",
                        new List<string> { "المدينة المختارة غير صحيحة" }
                    );
                }

                parent.CityId = request.CityId.Value;
                parent.City = cityExists; // Update navigation property
                fieldsUpdated.Add("city");
                _logger.LogInformation("Updating city for user {UserId}", userId);
            }

            // Step 8: Update Date of Birth (if provided)
            if (request.DateOfBirth.HasValue && request.DateOfBirth.Value.Date != parent.DateOfBirth.Date)
            {
                parent.DateOfBirth = request.DateOfBirth.Value;
                fieldsUpdated.Add("dateOfBirth");
                _logger.LogInformation("Updating date of birth for user {UserId}", userId);
            }

            // Step 9: Update Role/Gender (if provided)
            if (request.Role.HasValue && (int)parent.Gender != request.Role.Value)
            {
                parent.Gender = (ParentGender)request.Role.Value;
                fieldsUpdated.Add("role");
                _logger.LogInformation("Updating role for user {UserId}", userId);
            }

            // Step 10: Check if anything was actually updated
            if (fieldsUpdated.Count == 0)
            {
                return ApiResponse<UpdateParentProfileResponseDto>.SuccessResponse(
                    new UpdateParentProfileResponseDto
                    {
                        ParentId = parent.Id,
                        UserId = user.Id,
                        FullName = user.FullName,
                        Username = user.Username,
                        Email = user.Email,
                        CityName = parent.City.Name,
                        CityNameAr = parent.City.NameAr,
                        DateOfBirth = parent.DateOfBirth,
                        Role = GetRoleDisplayName(parent.Gender),
                        UpdatedAt = parent.UpdatedAt ?? parent.CreatedAt,
                        FieldsUpdated = fieldsUpdated,
                        Message = "لم يتم تغيير أي بيانات"
                    },
                    "لم يتم تحديث أي بيانات (البيانات المدخلة مطابقة للبيانات الحالية)"
                );
            }

            // Step 11: Update timestamps
            user.UpdatedAt = DateTime.UtcNow;
            parent.UpdatedAt = DateTime.UtcNow;

            // Step 12: Save changes
            await _unitOfWork.Users.UpdateAsync(user);
            await _unitOfWork.Parents.UpdateAsync(parent);
            await _unitOfWork.SaveChangesAsync();

            _logger.LogInformation(
                "Profile updated successfully for user {UserId}.  Fields: {Fields}",
                userId,
                string.Join(", ", fieldsUpdated)
            );

            // Step 13: Return success response
            var response = new UpdateParentProfileResponseDto
            {
                ParentId = parent.Id,
                UserId = user.Id,
                FullName = user.FullName,
                Username = user.Username,
                Email = user.Email,
                CityName = parent.City.Name,
                CityNameAr = parent.City.NameAr,
                DateOfBirth = parent.DateOfBirth,
                Role = GetRoleDisplayName(parent.Gender),
                UpdatedAt = parent.UpdatedAt.Value,
                FieldsUpdated = fieldsUpdated,
                Message = $"تم تحديث {fieldsUpdated.Count} حقل بنجاح"
            };

            return ApiResponse<UpdateParentProfileResponseDto>.SuccessResponse(
                response,
                "تم تحديث البيانات بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating profile for user ID: {UserId}", userId);
            return ApiResponse<UpdateParentProfileResponseDto>.FailureResponse(
                "حدث خطأ أثناء تحديث البيانات",
                new List<string> { "حدث خطأ غير متوقع.  يرجى المحاولة لاحقاً" }
            );
        }
    }

    /// <summary>
    /// Get role display name in Arabic
    /// </summary>
    private string GetRoleDisplayName(ParentGender gender)
    {
        return gender switch
        {
            ParentGender.Father => "أب",
            ParentGender.Mother => "أم",
            ParentGender.Educator => "مربي",
            _ => "غير محدد"
        };
    }

    /// <summary>
    /// Upload or update parent profile image
    /// </summary>
    public async Task<ApiResponse<UploadParentImageResponseDto>> UploadParentProfileImageAsync(
        Guid userId,
        IFormFile image)
    {
        try
        {
            _logger.LogInformation("Profile image upload requested for user ID: {UserId}", userId);

            // Step 1: Validate image file
            if (image == null || image.Length == 0)
            {
                return ApiResponse<UploadParentImageResponseDto>.FailureResponse(
                    "الصورة مطلوبة",
                    new List<string> { "يجب اختيار صورة للرفع" }
                );
            }

            // Step 2: Get parent
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(
                predicate: p => p.UserId == userId,
                includeProperties: "User"
            );

            if (parent == null)
            {
                _logger.LogWarning("Parent not found for user {UserId}", userId);
                return ApiResponse<UploadParentImageResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "هذه الوظيفة متاحة فقط لأولياء الأمور" }
                );
            }

            // Step 3: Check if user is active
            if (!parent.User.IsActive)
            {
                _logger.LogWarning("Inactive user attempted image upload: {UserId}", userId);
                return ApiResponse<UploadParentImageResponseDto>.FailureResponse(
                    "الحساب غير نشط",
                    new List<string> { "لا يمكن رفع الصورة لحساب غير نشط" }
                );
            }

            // Step 4: Delete old image if exists
            if (!string.IsNullOrEmpty(parent.ProfileImageUrl))
            {
                try
                {
                    await _imageService.DeleteImageAsync(parent.ProfileImageUrl);
                    _logger.LogInformation("Deleted old profile image for parent {ParentId}", parent.Id);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to delete old image for parent {ParentId}", parent.Id);
                    // Continue anyway - old image deletion failure shouldn't block upload
                }
            }

            // Step 5: Upload new image
            string newImageUrl;
            try
            {
                newImageUrl = await _imageService.UploadParentImageAsync(image, parent.Id);
                _logger.LogInformation("Uploaded new profile image for parent {ParentId}: {ImageUrl}",
                    parent.Id, newImageUrl);
            }
            catch (ArgumentException ex)
            {
                // Validation error from image service
                return ApiResponse<UploadParentImageResponseDto>.FailureResponse(
                    "فشل في رفع الصورة",
                    new List<string> { ex.Message }
                );
            }

            // Step 6: Update parent record
            parent.ProfileImageUrl = newImageUrl;
            parent.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Parents.UpdateAsync(parent);

            // Step 7: Update user timestamp
            parent.User.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Users.UpdateAsync(parent.User);

            // Step 8: Save changes
            await _unitOfWork.SaveChangesAsync();

            _logger.LogInformation("Profile image updated successfully for parent {ParentId}", parent.Id);

            // Step 9: Return success response
            var response = new UploadParentImageResponseDto
            {
                ParentId = parent.Id,
                ProfileImageUrl = newImageUrl,
                UploadedAt = DateTime.UtcNow,
                Message = "تم رفع الصورة بنجاح"
            };

            return ApiResponse<UploadParentImageResponseDto>.SuccessResponse(
                response,
                "تم تحديث صورة الملف الشخصي بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading profile image for user ID: {UserId}", userId);
            return ApiResponse<UploadParentImageResponseDto>.FailureResponse(
                "حدث خطأ أثناء رفع الصورة",
                new List<string> { "حدث خطأ غير متوقع.  يرجى المحاولة لاحقاً" }
            );
        }
    }

    /// <summary>
    /// Delete parent account permanently including all children and related data
    /// حذف حساب ولي الأمر نهائياً بما في ذلك جميع الأطفال والبيانات المرتبطة
    /// </summary>
    public async Task<ApiResponse<DeleteParentAccountResponseDto>> DeleteParentAccountAsync(
        Guid userId,
        DeleteParentAccountRequestDto request)
    {
        try
        {
            _logger.LogInformation("Account deletion requested for user ID: {UserId}", userId);

            // Step 1: Validate input
            var validator = new DeleteParentAccountRequestValidator();
            var (isValid, errors) = validator.Validate(request);

            if (!isValid)
            {
                _logger.LogWarning(
                    "Account deletion validation failed for user {UserId}. Errors: {Errors}",
                    userId,
                    string.Join(", ", errors)
                );

                return ApiResponse<DeleteParentAccountResponseDto>.FailureResponse(
                    "فشل في حذف الحساب",
                    errors
                );
            }

            // Step 2: Get user
            var user = await _unitOfWork.Users.GetFirstOrDefaultAsync(
                predicate: u => u.Id == userId
            );

            if (user == null)
            {
                _logger.LogWarning("User not found for account deletion: {UserId}", userId);
                return ApiResponse<DeleteParentAccountResponseDto>.FailureResponse(
                    "المستخدم غير موجود",
                    new List<string> { "لم يتم العثور على المستخدم" }
                );
            }

            // Step 3: Get parent with children
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(
                predicate: p => p.UserId == userId,
                includeProperties: "Children"
            );

            if (parent == null)
            {
                _logger.LogWarning("Parent not found for user {UserId}", userId);
                return ApiResponse<DeleteParentAccountResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "هذه الوظيفة متاحة فقط لأولياء الأمور" }
                );
            }

            // Step 4: Check if user is active
            if (!user.IsActive)
            {
                _logger.LogWarning("Inactive user attempted account deletion: {UserId}", userId);
                return ApiResponse<DeleteParentAccountResponseDto>.FailureResponse(
                    "الحساب غير نشط",
                    new List<string> { "لا يمكن حذف حساب غير نشط" }
                );
            }

            // Step 5: Get children count before deletion
            int childrenCount = parent.Children?.Count ?? 0;

            // Step 6: Delete children's profile images and records
            if (parent.Children != null && parent.Children.Any())
            {
                foreach (var child in parent.Children.ToList())
                {
                    // Delete child's profile image from Azure
                    if (!string.IsNullOrEmpty(child.ProfileImageUrl))
                    {
                        try
                        {
                            await _imageService.DeleteImageAsync(child.ProfileImageUrl);
                            _logger.LogInformation("Deleted profile image for child {ChildId}", child.Id);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning(ex, "Failed to delete image for child {ChildId}", child.Id);
                            // Continue with deletion even if image deletion fails
                        }
                    }

                    // Delete child record
                    await _unitOfWork.Children.DeleteAsync(child);
                    _logger.LogInformation("Deleted child record: {ChildId}", child.Id);
                }
            }

            // Step 8: Delete parent's profile image from Azure
            if (!string.IsNullOrEmpty(parent.ProfileImageUrl))
            {
                try
                {
                    await _imageService.DeleteImageAsync(parent.ProfileImageUrl);
                    _logger.LogInformation("Deleted profile image for parent {ParentId}", parent.Id);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Failed to delete image for parent {ParentId}", parent.Id);
                    // Continue with deletion even if image deletion fails
                }
            }

            // Step 9: Delete password reset tokens (get tokens before the transaction)
            var passwordResetTokens = await _unitOfWork.PasswordResetTokens.FindAsync(
                predicate: t => t.UserId == userId
            );
            var tokensList = passwordResetTokens.ToList();

            foreach (var token in tokensList)
            {
                await _unitOfWork.PasswordResetTokens.DeleteAsync(token);
            }
            _logger.LogInformation("Deleted {Count} password reset tokens for user {UserId}",
                tokensList.Count, userId);

            // Step 10: Delete parent record
            await _unitOfWork.Parents.DeleteAsync(parent);
            _logger.LogInformation("Deleted parent record: {ParentId}", parent.Id);

            // Step 11: Delete user record
            await _unitOfWork.Users.DeleteAsync(user);
            _logger.LogInformation("Deleted user record: {UserId}", userId);

            // Step 12: Save all changes to database
            await _unitOfWork.SaveChangesAsync();

            _logger.LogInformation(
                "Account deleted successfully for user {UserId}. Children deleted: {ChildrenCount}",
                userId,
                childrenCount
            );

            // Step 13: Return success response
            var response = new DeleteParentAccountResponseDto
            {
                Message = "تم حذف الحساب بنجاح",
                DeletedAt = DateTime.UtcNow,
                ChildrenDeleted = childrenCount
            };

            return ApiResponse<DeleteParentAccountResponseDto>.SuccessResponse(
                response,
                "تم حذف حسابك وجميع البيانات المرتبطة به بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting account for user ID: {UserId}", userId);
            return ApiResponse<DeleteParentAccountResponseDto>.FailureResponse(
                "حدث خطأ أثناء حذف الحساب",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة لاحقاً" }
            );
        }
    }

    /// <summary>
    /// Send email verification link to parent's email
    /// إرسال رابط التحقق من البريد الإلكتروني
    /// </summary>
    public async Task<ApiResponse<SendEmailVerificationResponseDto>> SendEmailVerificationAsync(Guid userId)
    {
        try
        {
            _logger.LogInformation("Email verification requested for user ID: {UserId}", userId);

            // Step 1: Get user
            var user = await _unitOfWork.Users.GetFirstOrDefaultAsync(
                predicate: u => u.Id == userId
            );

            if (user == null)
            {
                _logger.LogWarning("User not found for email verification: {UserId}", userId);
                return ApiResponse<SendEmailVerificationResponseDto>.FailureResponse(
                    "المستخدم غير موجود",
                    new List<string> { "لم يتم العثور على المستخدم" }
                );
            }

            // Step 2: Check if already verified
            if (user.IsEmailVerified)
            {
                _logger.LogInformation("Email already verified for user: {UserId}", userId);
                return ApiResponse<SendEmailVerificationResponseDto>.FailureResponse(
                    "البريد الإلكتروني مؤكد بالفعل",
                    new List<string> { "تم تأكيد بريدك الإلكتروني مسبقاً" }
                );
            }

            // Step 3: Check if user is active
            if (!user.IsActive)
            {
                _logger.LogWarning("Inactive user requested email verification: {UserId}", userId);
                return ApiResponse<SendEmailVerificationResponseDto>.FailureResponse(
                    "الحساب غير نشط",
                    new List<string> { "لا يمكن إرسال التحقق لحساب غير نشط" }
                );
            }

            // Step 4: Invalidate any existing tokens for this user
            var existingTokens = await _unitOfWork.EmailVerificationTokens.FindAsync(
                predicate: t => t.UserId == userId && !t.IsUsed
            );
            foreach (var token in existingTokens)
            {
                token.IsUsed = true;
                token.UsedAt = DateTime.UtcNow;
                await _unitOfWork.EmailVerificationTokens.UpdateAsync(token);
            }

            // Step 5: Generate new verification token
            var verificationToken = new EmailVerificationToken
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Token = Guid.NewGuid().ToString("N") + Guid.NewGuid().ToString("N"), // 64 char token
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddHours(24), // 24 hours expiry
                IsUsed = false
            };

            await _unitOfWork.EmailVerificationTokens.AddAsync(verificationToken);
            await _unitOfWork.SaveChangesAsync();

            // Step 6: Build verification link
            var verificationLink = $"{BaseApiUrl}/api/Parents/verify-email?token={verificationToken.Token}";

            // Step 7: Send email
            await _emailService.SendEmailVerificationAsync(
                user.Email,
                verificationLink,
                user.FullName
            );

            _logger.LogInformation("Email verification sent to {Email} for user {UserId}", user.Email, userId);

            // Step 8: Return success
            var response = new SendEmailVerificationResponseDto
            {
                Message = "تم إرسال رابط التحقق إلى بريدك الإلكتروني",
                Email = user.Email,
                SentAt = DateTime.UtcNow
            };

            return ApiResponse<SendEmailVerificationResponseDto>.SuccessResponse(
                response,
                "تم إرسال رابط التحقق بنجاح. يرجى التحقق من بريدك الإلكتروني."
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending email verification for user ID: {UserId}", userId);
            return ApiResponse<SendEmailVerificationResponseDto>.FailureResponse(
                "حدث خطأ أثناء إرسال رابط التحقق",
                new List<string> { $"خطأ SMTP: {ex.Message}" }
            );
        }
    }

    /// <summary>
    /// Verify email using token from verification link
    /// التحقق من البريد الإلكتروني باستخدام الرمز
    /// </summary>
    public async Task<ApiResponse<VerifyEmailResponseDto>> VerifyEmailAsync(string token)
    {
        try
        {
            _logger.LogInformation("Email verification attempt with token");

            // Step 1: Validate token not empty
            if (string.IsNullOrWhiteSpace(token))
            {
                return ApiResponse<VerifyEmailResponseDto>.FailureResponse(
                    "رمز التحقق غير صالح",
                    new List<string> { "رمز التحقق مطلوب" }
                );
            }

            // Step 2: Find token in database
            var verificationToken = await _unitOfWork.EmailVerificationTokens.GetFirstOrDefaultAsync(
                predicate: t => t.Token == token,
                includeProperties: "User"
            );

            if (verificationToken == null)
            {
                _logger.LogWarning("Invalid verification token attempted");
                return ApiResponse<VerifyEmailResponseDto>.FailureResponse(
                    "رمز التحقق غير صالح",
                    new List<string> { "رابط التحقق غير صحيح أو منتهي الصلاحية" }
                );
            }

            // Step 3: Check if token already used
            if (verificationToken.IsUsed)
            {
                _logger.LogWarning("Already used verification token attempted: {TokenId}", verificationToken.Id);
                return ApiResponse<VerifyEmailResponseDto>.FailureResponse(
                    "رابط التحقق مستخدم مسبقاً",
                    new List<string> { "تم استخدام هذا الرابط مسبقاً. يرجى طلب رابط جديد." }
                );
            }

            // Step 4: Check if token expired
            if (verificationToken.ExpiresAt < DateTime.UtcNow)
            {
                _logger.LogWarning("Expired verification token attempted: {TokenId}", verificationToken.Id);
                return ApiResponse<VerifyEmailResponseDto>.FailureResponse(
                    "انتهت صلاحية رابط التحقق",
                    new List<string> { "انتهت صلاحية هذا الرابط. يرجى طلب رابط جديد." }
                );
            }

            // Step 5: Check if email already verified
            if (verificationToken.User.IsEmailVerified)
            {
                // Mark token as used anyway
                verificationToken.IsUsed = true;
                verificationToken.UsedAt = DateTime.UtcNow;
                await _unitOfWork.EmailVerificationTokens.UpdateAsync(verificationToken);
                await _unitOfWork.SaveChangesAsync();

                return ApiResponse<VerifyEmailResponseDto>.SuccessResponse(
                    new VerifyEmailResponseDto
                    {
                        Message = "البريد الإلكتروني مؤكد بالفعل",
                        Email = verificationToken.User.Email,
                        VerifiedAt = verificationToken.User.EmailVerifiedAt ?? DateTime.UtcNow
                    },
                    "بريدك الإلكتروني مؤكد بالفعل"
                );
            }

            // Step 6: Mark email as verified
            verificationToken.User.IsEmailVerified = true;
            verificationToken.User.EmailVerifiedAt = DateTime.UtcNow;
            verificationToken.User.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Users.UpdateAsync(verificationToken.User);

            // Step 7: Mark token as used
            verificationToken.IsUsed = true;
            verificationToken.UsedAt = DateTime.UtcNow;
            await _unitOfWork.EmailVerificationTokens.UpdateAsync(verificationToken);

            await _unitOfWork.SaveChangesAsync();

            _logger.LogInformation("Email verified successfully for user: {UserId}", verificationToken.UserId);

            // Step 8: Return success
            var response = new VerifyEmailResponseDto
            {
                Message = "تم تأكيد البريد الإلكتروني بنجاح",
                Email = verificationToken.User.Email,
                VerifiedAt = DateTime.UtcNow
            };

            return ApiResponse<VerifyEmailResponseDto>.SuccessResponse(
                response,
                "تم تأكيد بريدك الإلكتروني بنجاح! شكراً لك."
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error verifying email with token");
            return ApiResponse<VerifyEmailResponseDto>.FailureResponse(
                "حدث خطأ أثناء التحقق من البريد الإلكتروني",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة لاحقاً" }
            );
        }
    }

    /// <summary>
    /// Get all children for the logged-in parent (for "All Children" view)
    /// جلب جميع أطفال ولي الأمر المسجل لعرض "جميع الأطفال"
    /// </summary>
    public async Task<ApiResponse<GetParentChildrenResponseDto>> GetParentChildrenAsync(Guid userId)
    {
        try
        {
            _logger.LogInformation("Fetching children for user ID: {UserId}", userId);

            // Step 1: Get parent by userId
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(
                predicate: p => p.UserId == userId,
                includeProperties: "User"
            );

            if (parent == null)
            {
                _logger.LogWarning("Parent not found for user ID: {UserId}", userId);
                return ApiResponse<GetParentChildrenResponseDto>.FailureResponse(
                    "ولي الأمر غير موجود",
                    new List<string> { "لم يتم العثور على بيانات ولي الأمر" }
                );
            }

            // Step 2: Check if user is active
            if (!parent.User.IsActive)
            {
                _logger.LogWarning("Inactive user attempted to fetch children: {UserId}", userId);
                return ApiResponse<GetParentChildrenResponseDto>.FailureResponse(
                    "الحساب غير نشط",
                    new List<string> { "هذا الحساب غير نشط" }
                );
            }

            // Step 3: Get all children for this parent
            var children = await _unitOfWork.Children.GetChildrenByParentIdAsync(parent.Id);

            // Step 4: Map to ChildSummaryDto with calculated fields
            var now = DateTime.UtcNow;
            const int activeThresholdMinutes = 5;

            var childrenDtos = children
                .OrderByDescending(c => c.CreatedAt) // Newest first
                .Select(child => new ChildSummaryDto
                {
                    ChildId = child.Id,
                    FullName = child.FullName,
                    PhotoUrl = child.ProfileImageUrl,
                    Age = CalculateAge(child.BirthDate),
                    IsActive = child.LastActivityAt.HasValue
                              && (now - child.LastActivityAt.Value).TotalMinutes <= activeThresholdMinutes,
                    HasAccount = !string.IsNullOrEmpty(child.ChildLoginId),
                    PrizeCount = 0 // Placeholder — will be implemented with prize/achievement system
                })
                .ToList();

            // Step 5: Build response
            var response = new GetParentChildrenResponseDto
            {
                TotalCount = childrenDtos.Count,
                Children = childrenDtos
            };

            _logger.LogInformation(
                "Successfully retrieved {Count} children for user {UserId}",
                childrenDtos.Count, userId
            );

            return ApiResponse<GetParentChildrenResponseDto>.SuccessResponse(
                response,
                $"تم جلب بيانات {childrenDtos.Count} طفل بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching children for user ID: {UserId}", userId);
            return ApiResponse<GetParentChildrenResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب بيانات الأطفال",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة لاحقاً" }
            );
        }
    }
}