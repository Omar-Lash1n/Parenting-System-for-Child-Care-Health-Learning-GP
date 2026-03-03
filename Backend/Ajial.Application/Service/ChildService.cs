using Ajial.Application.DTOs.Child;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Ajial.Application.Validators;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;
using Microsoft.AspNetCore.Http;

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
                ProfileCompletionPercentage = CalculateProfileCompletion(child)
            };

            ApplyAccountStatus(summary, child, firstName);

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

    private void ApplyAccountStatus<T>(T dto, Child child, string firstName)
        where T : class
    {
        // Determine age in full years
        var (ageYears, _, _) = CalculateExactAge(child.BirthDate);
        bool isEligible = ageYears >= 4;
        bool hasAccount = !string.IsNullOrEmpty(child.ChildLoginId);

        string message;
        string action;

        if (!isEligible)
        {
            message = $"يبدو ان {firstName} لم يتم 4 اعوام";
            action = "not_eligible";
        }
        else if (hasAccount)
        {
            message = $"يبدو ان {firstName} اتم 4 اعوام بحمدالله";
            action = "view_account";
        }
        else
        {
            message = $"يبدو ان {firstName} اتم 4 اعوام بحمدالله";
            action = "create_account";
        }

        // Use reflection-free approach via dynamic cast
        if (dto is ChildProfileSummaryDto summaryDto)
        {
            summaryDto.IsEligibleForAccount = isEligible;
            summaryDto.HasAccount = hasAccount;
            summaryDto.AccountStatusMessage = message;
            summaryDto.AccountAction = action;
        }
        else if (dto is ChildFileDataDto fileDto)
        {
            fileDto.IsEligibleForAccount = isEligible;
            fileDto.HasAccount = hasAccount;
            fileDto.AccountStatusMessage = message;
            fileDto.AccountAction = action;
        }
    }

    private int CalculateProfileCompletion(Child child)
    {
        int totalFields = 8;
        int filledFields = 0;

        // Personal Profile fields (always filled from child creation)
        if (!string.IsNullOrWhiteSpace(child.FullName)) filledFields++;   // name
        if (child.BirthDate != default) filledFields++;                    // age
        if (!string.IsNullOrWhiteSpace(child.Gender)) filledFields++;      // type

        // Medical Profile fields
        if (child.Height.HasValue) filledFields++;
        if (child.Weight.HasValue) filledFields++;
        if (child.HeadCircumference.HasValue) filledFields++;
        if (!string.IsNullOrWhiteSpace(child.BloodType)) filledFields++;
        if (!string.IsNullOrWhiteSpace(child.MedicalHistory)) filledFields++;

        return (int)Math.Round((double)filledFields / totalFields * 100);
    }

    private async Task<(Parent? parent, Child? child, string? error)> ValidateParentChildAccessAsync(Guid childId, Guid parentUserId)
    {
        var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == parentUserId);
        if (parent == null)
            return (null, null, "حساب ولي الأمر غير موجود");

        var child = await _unitOfWork.Children.GetByIdAsync(childId);
        if (child == null || child.ParentId != parent.Id)
            return (parent, null, "الطفل غير موجود أو لا ينتمي لهذا الحساب");

        return (parent, child, null);
    }

    public async Task<ApiResponse<ChildFileDataDto>> GetChildFileDataAsync(Guid childId, Guid parentUserId)
    {
        try
        {
            var (parent, child, error) = await ValidateParentChildAccessAsync(childId, parentUserId);
            if (error != null)
            {
                return ApiResponse<ChildFileDataDto>.FailureResponse(
                    "فشل في جلب بيانات الطفل",
                    new List<string> { error }
                );
            }

            var (years, months, days) = CalculateExactAge(child!.BirthDate);

            string firstName = string.IsNullOrWhiteSpace(child.FullName)
                ? ""
                : child.FullName.Split(' ', StringSplitOptions.RemoveEmptyEntries)[0];

            var dto = new ChildFileDataDto
            {
                ChildId = child.Id,
                FirstName = firstName,
                FullName = child.FullName,
                ProfileImageUrl = child.ProfileImageUrl,
                AgeYears = years,
                AgeMonths = months,
                AgeDays = days,
                Gender = child.Gender,
                Height = child.Height.HasValue ? $"{child.Height} سم" : null,
                Weight = child.Weight.HasValue ? $"{child.Weight} كجم" : null,
                HeadCircumference = child.HeadCircumference.HasValue ? $"{child.HeadCircumference} سم" : null,
                BloodType = child.BloodType,
                MedicalHistory = child.MedicalHistory,
                ProfileCompletionPercentage = CalculateProfileCompletion(child)
            };

            ApplyAccountStatus(dto, child, firstName);

            return ApiResponse<ChildFileDataDto>.SuccessResponse(
                dto,
                "تم جلب بيانات ملف الطفل بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<ChildFileDataDto>.FailureResponse(
                "حدث خطأ أثناء جلب بيانات ملف الطفل",
                new List<string> { ex.Message }
            );
        }
    }

    public async Task<ApiResponse<UpdateChildMedicalDataResponseDto>> UpdateChildMedicalDataAsync(
        Guid childId, Guid parentUserId, UpdateChildMedicalDataDto request)
    {
        try
        {
            var (parent, child, error) = await ValidateParentChildAccessAsync(childId, parentUserId);
            if (error != null)
            {
                return ApiResponse<UpdateChildMedicalDataResponseDto>.FailureResponse(
                    "فشل في تحديث بيانات الطفل",
                    new List<string> { error }
                );
            }

            var fieldsUpdated = new List<string>();

            // ── Personal Profile fields ──
            if (!string.IsNullOrWhiteSpace(request.FullName))
            {
                child!.FullName = request.FullName.Trim();
                fieldsUpdated.Add("FullName");
            }

            if (request.BirthDate.HasValue)
            {
                child!.BirthDate = request.BirthDate.Value;
                // Recalculate age in years
                child.Age = DateTime.Today.Year - request.BirthDate.Value.Year;
                if (request.BirthDate.Value.Date > DateTime.Today.AddYears(-child.Age)) child.Age--;
                fieldsUpdated.Add("BirthDate");
            }

            // ── Medical Profile fields ──
            if (request.Height.HasValue)
            {
                child!.Height = request.Height.Value;
                fieldsUpdated.Add("Height");
            }

            if (request.Weight.HasValue)
            {
                child!.Weight = request.Weight.Value;
                fieldsUpdated.Add("Weight");
            }

            if (request.HeadCircumference.HasValue)
            {
                child!.HeadCircumference = request.HeadCircumference.Value;
                fieldsUpdated.Add("HeadCircumference");
            }

            if (request.BloodType != null)
            {
                child!.BloodType = request.BloodType;
                fieldsUpdated.Add("BloodType");
            }

            if (request.MedicalHistory != null)
            {
                child!.MedicalHistory = request.MedicalHistory;
                fieldsUpdated.Add("MedicalHistory");
            }

            if (fieldsUpdated.Count == 0)
            {
                return ApiResponse<UpdateChildMedicalDataResponseDto>.FailureResponse(
                    "لم يتم تقديم أي بيانات للتحديث",
                    new List<string> { "يرجى إرسال حقل واحد على الأقل للتحديث" }
                );
            }

            child!.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Children.UpdateAsync(child);
            await _unitOfWork.SaveAsync();

            var response = new UpdateChildMedicalDataResponseDto
            {
                ChildId = child.Id,
                FieldsUpdated = fieldsUpdated,
                ProfileCompletionPercentage = CalculateProfileCompletion(child)
            };

            return ApiResponse<UpdateChildMedicalDataResponseDto>.SuccessResponse(
                response,
                "تم تحديث البيانات الطبية بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<UpdateChildMedicalDataResponseDto>.FailureResponse(
                "حدث خطأ أثناء تحديث البيانات الطبية",
                new List<string> { ex.Message }
            );
        }
    }

    public async Task<ApiResponse<DeleteChildResponseDto>> DeleteChildAsync(Guid childId, Guid parentUserId)
    {
        try
        {
            var (parent, child, error) = await ValidateParentChildAccessAsync(childId, parentUserId);
            if (error != null)
            {
                return ApiResponse<DeleteChildResponseDto>.FailureResponse(
                    "فشل في حذف الطفل",
                    new List<string> { error }
                );
            }

            string childName = child!.FullName;

            // Delete profile image if it exists and is not a default avatar
            if (!string.IsNullOrEmpty(child.ProfileImageUrl) &&
                !child.ProfileImageUrl.Contains("default"))
            {
                try
                {
                    await _imageService.DeleteImageAsync(child.ProfileImageUrl);
                }
                catch
                {
                    // Continue with deletion even if image cleanup fails
                }
            }

            await _unitOfWork.Children.DeleteAsync(child);
            await _unitOfWork.SaveAsync();

            var response = new DeleteChildResponseDto
            {
                ChildId = childId,
                ChildName = childName
            };

            return ApiResponse<DeleteChildResponseDto>.SuccessResponse(
                response,
                $"تم حذف ملف {childName} بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<DeleteChildResponseDto>.FailureResponse(
                "حدث خطأ أثناء حذف الطفل",
                new List<string> { ex.Message }
            );
        }
    }

    public async Task<ApiResponse<UploadChildImageResponseDto>> UploadChildProfileImageAsync(
        Guid childId, Guid parentUserId, IFormFile image)
    {
        try
        {
            // Step 1: Validate image
            if (image == null || image.Length == 0)
            {
                return ApiResponse<UploadChildImageResponseDto>.FailureResponse(
                    "الصورة مطلوبة",
                    new List<string> { "يجب اختيار صورة للرفع" }
                );
            }

            // Step 2: Validate parent-child ownership
            var (parent, child, error) = await ValidateParentChildAccessAsync(childId, parentUserId);
            if (error != null)
            {
                return ApiResponse<UploadChildImageResponseDto>.FailureResponse(
                    "فشل في رفع الصورة",
                    new List<string> { error }
                );
            }

            // Step 3: Delete old image if it exists (and is not the default avatar)
            if (!string.IsNullOrEmpty(child!.ProfileImageUrl) &&
                !child.ProfileImageUrl.Contains("default"))
            {
                try
                {
                    await _imageService.DeleteImageAsync(child.ProfileImageUrl);
                }
                catch
                {
                    // Continue even if old image deletion fails
                }
            }

            // Step 4: Upload new image
            string newImageUrl;
            try
            {
                newImageUrl = await _imageService.UploadChildImageAsync(image, child.Id);
            }
            catch (ArgumentException ex)
            {
                return ApiResponse<UploadChildImageResponseDto>.FailureResponse(
                    "فشل في رفع الصورة",
                    new List<string> { ex.Message }
                );
            }

            // Step 5: Update child record
            child.ProfileImageUrl = newImageUrl;
            child.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Children.UpdateAsync(child);
            await _unitOfWork.SaveAsync();

            var response = new UploadChildImageResponseDto
            {
                ChildId = child.Id,
                ProfileImageUrl = newImageUrl,
                UploadedAt = DateTime.UtcNow,
                Message = "تم رفع الصورة بنجاح"
            };

            return ApiResponse<UploadChildImageResponseDto>.SuccessResponse(
                response,
                "تم تحديث صورة ملف الطفل بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<UploadChildImageResponseDto>.FailureResponse(
                "حدث خطأ أثناء رفع الصورة",
                new List<string> { ex.Message }
            );
        }
    }

    // ═══════════════════════════════════════════════════════
    // ──────── Child Account Management Methods ────────
    // ═══════════════════════════════════════════════════════

    public async Task<ApiResponse<ChildAccountDetailsDto>> GetChildAccountDetailsAsync(
        Guid childId, Guid parentUserId)
    {
        try
        {
            var (parent, child, error) = await ValidateParentChildAccessAsync(childId, parentUserId);
            if (error != null)
            {
                return ApiResponse<ChildAccountDetailsDto>.FailureResponse(
                    "فشل في جلب بيانات الحساب",
                    new List<string> { error }
                );
            }

            // Verify child has an account
            if (string.IsNullOrEmpty(child!.ChildLoginId))
            {
                return ApiResponse<ChildAccountDetailsDto>.FailureResponse(
                    "الطفل لا يملك حساب",
                    new List<string> { "هذا الطفل لم يتم إنشاء حساب له بعد" }
                );
            }

            var dto = new ChildAccountDetailsDto
            {
                ChildId = child.Id,
                ChildLoginId = child.ChildLoginId,
                IsAccountActive = child.IsActive
            };

            return ApiResponse<ChildAccountDetailsDto>.SuccessResponse(
                dto, "تم جلب بيانات حساب الطفل بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ChildAccountDetailsDto>.FailureResponse(
                "حدث خطأ أثناء جلب بيانات الحساب",
                new List<string> { ex.Message }
            );
        }
    }

    public async Task<ApiResponse<ChildAccountDetailsDto>> UpdateChildLoginIdAsync(
        Guid childId, Guid parentUserId, UpdateChildLoginIdDto request)
    {
        try
        {
            // Validate input
            if (string.IsNullOrWhiteSpace(request.NewChildLoginId))
            {
                return ApiResponse<ChildAccountDetailsDto>.FailureResponse(
                    "فشل في تحديث كود الطفل",
                    new List<string> { "كود الطفل الجديد مطلوب" }
                );
            }

            var (parent, child, error) = await ValidateParentChildAccessAsync(childId, parentUserId);
            if (error != null)
            {
                return ApiResponse<ChildAccountDetailsDto>.FailureResponse(
                    "فشل في تحديث كود الطفل",
                    new List<string> { error }
                );
            }

            if (string.IsNullOrEmpty(child!.ChildLoginId))
            {
                return ApiResponse<ChildAccountDetailsDto>.FailureResponse(
                    "الطفل لا يملك حساب",
                    new List<string> { "هذا الطفل لم يتم إنشاء حساب له بعد" }
                );
            }

            var trimmedId = request.NewChildLoginId.Trim();

            // Check if same as current
            if (trimmedId == child.ChildLoginId)
            {
                return ApiResponse<ChildAccountDetailsDto>.FailureResponse(
                    "فشل في تحديث كود الطفل",
                    new List<string> { "كود الطفل الجديد مطابق للكود الحالي" }
                );
            }

            // Check uniqueness
            var existing = await _unitOfWork.Children.GetFirstOrDefaultAsync(
                c => c.ChildLoginId == trimmedId && c.Id != childId);
            if (existing != null)
            {
                return ApiResponse<ChildAccountDetailsDto>.FailureResponse(
                    "فشل في تحديث كود الطفل",
                    new List<string> { "هذا الكود مستخدم من قبل طفل آخر. يرجى اختيار كود مختلف" }
                );
            }

            // Update
            child.ChildLoginId = trimmedId;
            child.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Children.UpdateAsync(child);
            await _unitOfWork.SaveAsync();

            var dto = new ChildAccountDetailsDto
            {
                ChildId = child.Id,
                ChildLoginId = child.ChildLoginId,
                IsAccountActive = child.IsActive
            };

            return ApiResponse<ChildAccountDetailsDto>.SuccessResponse(
                dto, "تم تحديث كود الطفل بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ChildAccountDetailsDto>.FailureResponse(
                "حدث خطأ أثناء تحديث كود الطفل",
                new List<string> { ex.Message }
            );
        }
    }

    public async Task<ApiResponse<string>> UpdateChildPasswordAsync(
        Guid childId, Guid parentUserId, UpdateChildPasswordDto request)
    {
        try
        {
            // Validate input
            if (request.NewFruitPasswordCodes == null || request.NewFruitPasswordCodes.Count != 5)
            {
                return ApiResponse<string>.FailureResponse(
                    "فشل في تحديث كلمة المرور",
                    new List<string> { "كلمة المرور يجب أن تتكون من 5 فواكه" }
                );
            }

            if (request.ConfirmFruitPasswordCodes == null || request.ConfirmFruitPasswordCodes.Count != 5)
            {
                return ApiResponse<string>.FailureResponse(
                    "فشل في تحديث كلمة المرور",
                    new List<string> { "تأكيد كلمة المرور يجب أن يتكون من 5 فواكه" }
                );
            }

            // Check passwords match
            var newPassword = string.Join("", request.NewFruitPasswordCodes);
            var confirmPassword = string.Join("", request.ConfirmFruitPasswordCodes);
            if (newPassword != confirmPassword)
            {
                return ApiResponse<string>.FailureResponse(
                    "فشل في تحديث كلمة المرور",
                    new List<string> { "كلمة المرور الجديدة وتأكيدها غير متطابقين" }
                );
            }

            var (parent, child, error) = await ValidateParentChildAccessAsync(childId, parentUserId);
            if (error != null)
            {
                return ApiResponse<string>.FailureResponse(
                    "فشل في تحديث كلمة المرور",
                    new List<string> { error }
                );
            }

            if (string.IsNullOrEmpty(child!.ChildLoginId))
            {
                return ApiResponse<string>.FailureResponse(
                    "الطفل لا يملك حساب",
                    new List<string> { "هذا الطفل لم يتم إنشاء حساب له بعد" }
                );
            }

            // Hash and update
            child.PasswordHash = _passwordHasher.HashPassword(newPassword);
            child.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Children.UpdateAsync(child);
            await _unitOfWork.SaveAsync();

            return ApiResponse<string>.SuccessResponse(
                "تم تحديث كلمة المرور بنجاح",
                "تم تغيير كلمة مرور الطفل بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<string>.FailureResponse(
                "حدث خطأ أثناء تحديث كلمة المرور",
                new List<string> { ex.Message }
            );
        }
    }

    public async Task<ApiResponse<ChildAccountDetailsDto>> ToggleChildAccountAsync(
        Guid childId, Guid parentUserId, ToggleChildAccountDto request)
    {
        try
        {
            var (parent, child, error) = await ValidateParentChildAccessAsync(childId, parentUserId);
            if (error != null)
            {
                return ApiResponse<ChildAccountDetailsDto>.FailureResponse(
                    "فشل في تحديث حالة الحساب",
                    new List<string> { error }
                );
            }

            if (string.IsNullOrEmpty(child!.ChildLoginId))
            {
                return ApiResponse<ChildAccountDetailsDto>.FailureResponse(
                    "الطفل لا يملك حساب",
                    new List<string> { "هذا الطفل لم يتم إنشاء حساب له بعد" }
                );
            }

            child.IsActive = request.IsActive;
            child.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Children.UpdateAsync(child);
            await _unitOfWork.SaveAsync();

            string message = request.IsActive
                ? "تم تفعيل حساب الطفل بنجاح"
                : "تم تعطيل حساب الطفل بنجاح";

            var dto = new ChildAccountDetailsDto
            {
                ChildId = child.Id,
                ChildLoginId = child.ChildLoginId,
                IsAccountActive = child.IsActive
            };

            return ApiResponse<ChildAccountDetailsDto>.SuccessResponse(dto, message);
        }
        catch (Exception ex)
        {
            return ApiResponse<ChildAccountDetailsDto>.FailureResponse(
                "حدث خطأ أثناء تحديث حالة الحساب",
                new List<string> { ex.Message }
            );
        }
    }
}