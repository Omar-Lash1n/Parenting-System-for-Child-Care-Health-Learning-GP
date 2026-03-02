using Ajial.Application.DTOs.Child;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Ajial.Application.Validators;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Services;

public class ChildService : IChildService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IImageService _imageService;
    private readonly IPasswordHasher _passwordHasher;

    public ChildService(
        IUnitOfWork unitOfWork,
        IImageService imageService,
        IPasswordHasher passwordHasher)
    {
        _unitOfWork = unitOfWork;
        _imageService = imageService;
        _passwordHasher = passwordHasher;
    }

    public async Task<ApiResponse<AddChildResponseDto>> AddChildAsync(
        AddChildRequestDto request,
        Guid parentId)
    {
        try
        {
            // Step 1: Validate input
            var validator = new AddChildRequestValidator();
            var (isValid, errors) = validator.Validate(request);

            if (!isValid)
            {
                return ApiResponse<AddChildResponseDto>.FailureResponse(
                    "فشل في إضافة الطفل",
                    errors
                );
            }

            // Step 2: Verify parent exists
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(
                p => p.UserId == parentId,
                includeProperties: "User"
            );

            if (parent == null)
            {
                return ApiResponse<AddChildResponseDto>.FailureResponse(
                    "فشل في إضافة الطفل",
                    new List<string> { "الحساب غير موجود" }
                );
            }

            // Step 3: Calculate age
            int age = AddChildRequestValidator.CalculateAge(request.BirthDate);
            bool requiresPassword = age >= 4 && age <= 13;

            // Step 4: Check if ChildLoginId is unique (if provided)
            if (requiresPassword && !string.IsNullOrEmpty(request.ChildLoginId))
            {
                var existingChild = await _unitOfWork.Children.GetFirstOrDefaultAsync(
                    c => c.ChildLoginId == request.ChildLoginId.Trim()
                );

                if (existingChild != null)
                {
                    return ApiResponse<AddChildResponseDto>.FailureResponse(
                        "فشل في إضافة الطفل",
                        new List<string> { "معرف تسجيل الدخول مستخدم بالفعل. يرجى اختيار معرف آخر" }
                    );
                }
            }

            // Step 5: Create child entity (generate ID first for image upload)
            var childId = Guid.NewGuid();

            // Step 6: Upload profile image (if provided)
            string? profileImageUrl = null;
            if (request.ProfileImage != null)
            {
                try
                {
                    profileImageUrl = await _imageService.UploadChildImageAsync(
                        request.ProfileImage,
                        childId
                    );
                }
                catch (Exception ex)
                {
                    return ApiResponse<AddChildResponseDto>.FailureResponse(
                        "فشل في رفع صورة الطفل",
                        new List<string> { ex.Message }
                    );
                }
            }
            else
            {
                // Use default avatar based on gender
                profileImageUrl = _imageService.GetDefaultChildAvatar(request.Gender);
            }

            // Step 7: Create child entity
            var child = new Child
            {
                Id = childId,
                ParentId = parent.Id,
                FullName = request.FullName.Trim(),
                BirthDate = request.BirthDate.Date,
                Age = age,
                Gender = NormalizeGender(request.Gender),
                ProfileImageUrl = profileImageUrl,
                ChildLoginId = requiresPassword ? request.ChildLoginId?.Trim() : null,
                PasswordHash = null,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                IsActive = true
            };

            // Step 8: Hash password if required (ages 4-13)
            if (requiresPassword && request.FruitPasswordCodes != null && request.FruitPasswordCodes.Any())
            {
                // Combine fruit codes into a single password string
                var combinedPassword = string.Join("", request.FruitPasswordCodes);

                // Hash the password using your IPasswordHasher
                child.PasswordHash = _passwordHasher.HashPassword(combinedPassword);
            }

            // Step 9: Save to database
            await _unitOfWork.Children.AddAsync(child);
            await _unitOfWork.SaveAsync();

            // Step 10: Prepare response
            var response = new AddChildResponseDto
            {
                ChildId = child.Id,
                FullName = child.FullName,
                BirthDate = child.BirthDate,
                Age = child.Age,
                Gender = child.Gender,
                ProfileImageUrl = child.ProfileImageUrl,
                ChildLoginId = child.ChildLoginId,
                RequiresPassword = requiresPassword,
                Message = requiresPassword
                    ? $"تم إضافة الطفل {child.FullName} بنجاح. يمكن للطفل تسجيل الدخول باستخدام المعرف: {child.ChildLoginId}"
                    : $"تم إضافة الطفل {child.FullName} بنجاح",
                CreatedAt = child.CreatedAt
            };

            return ApiResponse<AddChildResponseDto>.SuccessResponse(
                response,
                "تم إضافة الطفل بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<AddChildResponseDto>.FailureResponse(
                "حدث خطأ أثناء إضافة الطفل",
                new List<string> { ex.Message }
            );
        }
    }

    public async Task<ApiResponse<List<FruitOptionDto>>> GetAvailableFruitsAsync()
    {
        try
        {
            await Task.CompletedTask;
            var fruits = new List<FruitOptionDto>
            {
                new FruitOptionDto { FruitCode = "apple2025", FruitNameAr = "تفاح", FruitNameEn = "Apple", DisplayOrder = 1 },
                new FruitOptionDto { FruitCode = "banana2025", FruitNameAr = "موز", FruitNameEn = "Banana", DisplayOrder = 2 },
                new FruitOptionDto { FruitCode = "orange2025", FruitNameAr = "برتقال", FruitNameEn = "Orange", DisplayOrder = 3 },
                new FruitOptionDto { FruitCode = "grape2025", FruitNameAr = "عنب", FruitNameEn = "Grape", DisplayOrder = 4 },
                new FruitOptionDto { FruitCode = "pear2025", FruitNameAr = "كمثرى", FruitNameEn = "Pear", DisplayOrder = 5 },
                new FruitOptionDto { FruitCode = "strawberry2025", FruitNameAr = "فراولة", FruitNameEn = "Strawberry", DisplayOrder = 6 },
                new FruitOptionDto { FruitCode = "watermelon2025", FruitNameAr = "بطيخ", FruitNameEn = "Watermelon", DisplayOrder = 7 },
                new FruitOptionDto { FruitCode = "pineapple2025", FruitNameAr = "أناناس", FruitNameEn = "Pineapple", DisplayOrder = 8 },
                new FruitOptionDto { FruitCode = "fig2025", FruitNameAr = "تين", FruitNameEn = "Fig", DisplayOrder = 9 },
                new FruitOptionDto { FruitCode = "lemon2025", FruitNameAr = "ليمون", FruitNameEn = "Lemon", DisplayOrder = 10 }
            };

            return ApiResponse<List<FruitOptionDto>>.SuccessResponse(
                fruits,
                "تم جلب قائمة الفواكه بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<List<FruitOptionDto>>.FailureResponse(
                "حدث خطأ أثناء جلب قائمة الفواكه",
                new List<string> { ex.Message }
            );
        }
    }

    public async Task<ApiResponse<bool>> CheckChildLoginIdAvailabilityAsync(string childLoginId)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(childLoginId))
            {
                return ApiResponse<bool>.FailureResponse(
                    "معرف تسجيل الدخول مطلوب",
                    new List<string> { "يرجى إدخال معرف تسجيل الدخول" }
                );
            }

            var existingChild = await _unitOfWork.Children.GetFirstOrDefaultAsync(
                c => c.ChildLoginId == childLoginId.Trim()
            );

            bool isAvailable = existingChild == null;

            return ApiResponse<bool>.SuccessResponse(
                isAvailable,
                isAvailable
                    ? "معرف تسجيل الدخول متاح"
                    : "معرف تسجيل الدخول مستخدم بالفعل"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<bool>.FailureResponse(
                "حدث خطأ أثناء التحقق من معرف تسجيل الدخول",
                new List<string> { ex.Message }
            );
        }
    }

    private string NormalizeGender(string gender)
    {
        return gender.ToLower() switch
        {
            "male" => "ذكر",
            "female" => "أنثى",
            _ => gender
        };
    }

    public async Task<ApiResponse<ChildProfileSummaryDto>> GetChildProfileSummaryAsync(Guid childId, Guid parentId)
    {
        try
        {
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == parentId);
            if (parent == null)
            {
                return ApiResponse<ChildProfileSummaryDto>.FailureResponse(
                    "فشل في جلب بيانات الطفل",
                    new List<string> { "حساب ولي الأمر غير موجود" }
                );
            }

            var child = await _unitOfWork.Children.GetByIdAsync(childId);

            if (child == null || child.ParentId != parent.Id)
            {
                return ApiResponse<ChildProfileSummaryDto>.FailureResponse(
                    "فشل في جلب بيانات الطفل",
                    new List<string> { "الطفل غير موجود أو لا ينتمي لهذا الحساب" }
                );
            }

            string firstName = string.IsNullOrWhiteSpace(child.FullName)
                ? ""
                : child.FullName.Split(' ', StringSplitOptions.RemoveEmptyEntries)[0];

            var (years, months, days) = CalculateExactAge(child.BirthDate);

            var summary = new ChildProfileSummaryDto
            {
                ChildId = child.Id,
                FirstName = firstName,
                AgeYears = years,
                AgeMonths = months,
                AgeDays = days,
                ProfileImageUrl = child.ProfileImageUrl,
                ProfileCompletionPercentage = 0
            };

            return ApiResponse<ChildProfileSummaryDto>.SuccessResponse(
                summary,
                "تم جلب بيانات الطفل بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<ChildProfileSummaryDto>.FailureResponse(
                "حدث خطأ أثناء جلب بيانات الطفل",
                new List<string> { ex.Message }
            );
        }
    }

    private (int years, int months, int days) CalculateExactAge(DateTime birthDate)
    {
        DateTime today = DateTime.Today;
        int years = today.Year - birthDate.Year;
        int months = today.Month - birthDate.Month;
        int days = today.Day - birthDate.Day;

        if (days < 0)
        {
            months--;
            days += DateTime.DaysInMonth(today.Year, today.Month == 1 ? 12 : today.Month - 1);
        }

        if (months < 0)
        {
            years--;
            months += 12;
        }

        if (years < 0) return (0, 0, 0);

        return (years, months, days);
    }
}