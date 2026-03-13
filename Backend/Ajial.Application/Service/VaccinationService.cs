using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Vaccination;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Services;

public class VaccinationService : IVaccinationService
{
    private readonly IUnitOfWork _unitOfWork;

    public VaccinationService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    // ────────────────────────────────────────────
    // 1. Welcome Page
    // ────────────────────────────────────────────

    /// <inheritdoc />
    public async Task<ApiResponse<VaccinationWelcomeResponseDto>> GetVaccinationWelcomeAsync(
        Guid childId, Guid parentUserId)
    {
        try
        {
            var (parent, child, error) = await ValidateParentChildAsync<VaccinationWelcomeResponseDto>(childId, parentUserId);
            if (error != null) return error;

            var response = new VaccinationWelcomeResponseDto
            {
                ChildId = child!.Id,
                FullName = child.FullName.Split(' ')[0],
                ProfileImageUrl = child.ProfileImageUrl,
                HasCompletedVaccinationSurvey = child.HasCompletedVaccinationSurvey,
                HasCompletedAdditionalVaccinationSurvey = child.HasCompletedAdditionalVaccinationSurvey
            };

            return ApiResponse<VaccinationWelcomeResponseDto>.SuccessResponse(
                response,
                $"تجهيز سجل التطعيمات - {child.FullName}"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<VaccinationWelcomeResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب بيانات صفحة الترحيب",
                new List<string> { ex.Message }
            );
        }
    }

    // ────────────────────────────────────────────
    // 2. Get Vaccination Survey
    // ────────────────────────────────────────────

    /// <inheritdoc />
    public async Task<ApiResponse<GetVaccinationSurveyResponseDto>> GetVaccinationSurveyAsync(
        Guid childId, Guid parentUserId)
    {
        try
        {
            var (parent, child, error) = await ValidateParentChildAsync<GetVaccinationSurveyResponseDto>(childId, parentUserId);
            if (error != null) return error;

            // Calculate age in months + days
            var (ageMonths, ageDays) = CalculateAgeInMonthsAndDays(child!.BirthDate);

            // Load all milestones
            var milestones = (await _unitOfWork.VaccinationMilestones.GetAllAsync())
                .Where(m => m.IsActive)
                .OrderBy(m => m.SortOrder)
                .ToList();

            // Load existing vaccination records for this child
            var existingRecords = (await _unitOfWork.ChildVaccinations.FindAsync(
                cv => cv.ChildId == childId
            )).ToDictionary(cv => cv.VaccinationMilestoneId);

            // Build milestone DTOs with business rules
            var milestoneDtos = milestones.Select(m =>
            {
                var (status, isAutoSelected, isDisabled) = ApplyBusinessRules(m.AgeInMonths, ageMonths);

                // If there's an existing record, use its IsTaken value
                bool isTaken = existingRecords.TryGetValue(m.Id, out var record)
                    ? record.IsTaken
                    : isAutoSelected; // default based on rule

                return new VaccinationMilestoneDto
                {
                    MilestoneId = m.Id,
                    NameAr = m.NameAr,
                    NameEn = m.NameEn,
                    AgeInMonths = m.AgeInMonths,
                    VaccinesAr = m.VaccinesAr,
                    VaccinesEn = m.VaccinesEn,
                    Status = status,
                    IsAutoSelected = isAutoSelected,
                    IsDisabled = isDisabled,
                    IsTaken = isTaken
                };
            }).ToList();

            var response = new GetVaccinationSurveyResponseDto
            {
                ChildId = child.Id,
                ChildName = child.FullName.Split(' ')[0],
                ChildImageUrl = child.ProfileImageUrl,
                AgeMonths = ageMonths,
                AgeDays = ageDays,
                AgeFormatted = FormatAgeArabic(ageMonths, ageDays),
                Milestones = milestoneDtos
            };

            return ApiResponse<GetVaccinationSurveyResponseDto>.SuccessResponse(
                response,
                $"تم جلب استبيان التطعيمات - {child.FullName}"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<GetVaccinationSurveyResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب استبيان التطعيمات",
                new List<string> { ex.Message }
            );
        }
    }

    // ────────────────────────────────────────────
    // 3. Submit Vaccination Survey
    // ────────────────────────────────────────────

    /// <inheritdoc />
    public async Task<ApiResponse<SubmitVaccinationSurveyResponseDto>> SubmitVaccinationSurveyAsync(
        SubmitVaccinationSurveyRequestDto request, Guid parentUserId)
    {
        try
        {
            var (parent, child, error) = await ValidateParentChildAsync<SubmitVaccinationSurveyResponseDto>(request.ChildId, parentUserId);
            if (error != null) return error;

            // Calculate age for validation
            var (ageMonths, _) = CalculateAgeInMonthsAndDays(child!.BirthDate);

            // Load milestones for validation
            var milestones = (await _unitOfWork.VaccinationMilestones.GetAllAsync())
                .Where(m => m.IsActive)
                .ToDictionary(m => m.Id);

            // Validate: no future milestones submitted as taken
            foreach (var selection in request.Selections)
            {
                if (!milestones.TryGetValue(selection.MilestoneId, out var milestone))
                {
                    return ApiResponse<SubmitVaccinationSurveyResponseDto>.FailureResponse(
                        "تطعيم غير صالح",
                        new List<string> { $"التطعيم رقم {selection.MilestoneId} غير موجود" }
                    );
                }

                var (_, _, isDisabled) = ApplyBusinessRules(milestone.AgeInMonths, ageMonths);

                if (isDisabled && selection.IsTaken)
                {
                    return ApiResponse<SubmitVaccinationSurveyResponseDto>.FailureResponse(
                        "لا يمكن تسجيل تطعيم مستقبلي",
                        new List<string> { $"لا يمكن تسجيل {milestone.NameAr} لأن عمر الطفل لم يصل بعد" }
                    );
                }
            }

            // Load existing records for this child
            var existingRecords = (await _unitOfWork.ChildVaccinations.FindAsync(
                cv => cv.ChildId == request.ChildId
            )).ToDictionary(cv => cv.VaccinationMilestoneId);

            var now = DateTime.UtcNow;

            // Upsert each selection
            foreach (var selection in request.Selections)
            {
                if (existingRecords.TryGetValue(selection.MilestoneId, out var existing))
                {
                    // Update existing record
                    existing.IsTaken = selection.IsTaken;
                    existing.UpdatedAt = now;
                    await _unitOfWork.ChildVaccinations.UpdateAsync(existing);
                }
                else
                {
                    // Create new record
                    var newRecord = new ChildVaccination
                    {
                        Id = Guid.NewGuid(),
                        ChildId = request.ChildId,
                        VaccinationMilestoneId = selection.MilestoneId,
                        IsTaken = selection.IsTaken,
                        RecordedAt = now,
                        UpdatedAt = now
                    };
                    await _unitOfWork.ChildVaccinations.AddAsync(newRecord);
                }
            }

            // Mark the main survey as completed
            child!.HasCompletedVaccinationSurvey = true;
            await _unitOfWork.Children.UpdateAsync(child);

            await _unitOfWork.SaveAsync();

            int takenCount = request.Selections.Count(s => s.IsTaken);

            var response = new SubmitVaccinationSurveyResponseDto
            {
                ChildId = request.ChildId,
                TotalMilestones = request.Selections.Count,
                TakenCount = takenCount,
                Message = $"تم تسجيل {takenCount} تطعيم من أصل {request.Selections.Count} بنجاح"
            };

            return ApiResponse<SubmitVaccinationSurveyResponseDto>.SuccessResponse(
                response,
                "تم حفظ استبيان التطعيمات بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<SubmitVaccinationSurveyResponseDto>.FailureResponse(
                "حدث خطأ أثناء حفظ استبيان التطعيمات",
                new List<string> { ex.Message }
            );
        }
    }

    // ════════════════════════════════════════════
    //  PRIVATE HELPERS
    // ════════════════════════════════════════════

    /// <summary>
    /// التحقق من ولي الأمر والطفل - Validate parent exists, child exists, and ownership
    /// </summary>
    private async Task<(Parent? parent, Child? child, ApiResponse<T>? error)>
        ValidateParentChildAsync<T>(Guid childId, Guid parentUserId)
    {
        var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(
            p => p.UserId == parentUserId
        );

        if (parent == null)
        {
            return (null, null, ApiResponse<T>.FailureResponse(
                "ولي الأمر غير موجود",
                new List<string> { "لم يتم العثور على حساب ولي الأمر" }
            ));
        }

        var child = await _unitOfWork.Children.GetByIdAsync(childId);

        if (child == null)
        {
            return (parent, null, ApiResponse<T>.FailureResponse(
                "الطفل غير موجود",
                new List<string> { "لم يتم العثور على بيانات الطفل" }
            ));
        }

        if (child.ParentId != parent.Id)
        {
            return (parent, child, ApiResponse<T>.FailureResponse(
                "غير مصرح",
                new List<string> { "هذا الطفل لا ينتمي إلى حسابك" }
            ));
        }

        return (parent, child, null);
    }

    /// <summary>
    /// حساب العمر بالشهور والأيام
    /// </summary>
    private static (int months, int days) CalculateAgeInMonthsAndDays(DateTime birthDate)
    {
        var today = DateTime.UtcNow.Date;
        var birth = birthDate.Date;

        int months = (today.Year - birth.Year) * 12 + (today.Month - birth.Month);
        int days = today.Day - birth.Day;

        if (days < 0)
        {
            months--;
            var previousMonth = today.AddMonths(-1);
            days += DateTime.DaysInMonth(previousMonth.Year, previousMonth.Month);
        }

        return (Math.Max(0, months), Math.Max(0, days));
    }

    /// <summary>
    /// تطبيق قواعد الأعمال A/B/C/D
    /// </summary>
    private static (string status, bool isAutoSelected, bool isDisabled) ApplyBusinessRules(
        int milestoneAgeMonths, int childAgeMonths)
    {
        // Rule D: Child is 18+ months → all milestones are past & editable
        if (childAgeMonths >= 18)
            return ("Past", true, false);

        // Rule A: Past milestone → auto-selected, editable
        if (milestoneAgeMonths < childAgeMonths)
            return ("Past", true, false);

        // Rule B: Current month milestone → unselected, editable
        if (milestoneAgeMonths == childAgeMonths)
            return ("Current", false, false);

        // Rule C: Future milestone → disabled
        return ("Future", false, true);
    }

    /// <summary>
    /// تنسيق العمر بالعربي مع قواعد اللغة الصحيحة
    /// </summary>
    private static string FormatAgeArabic(int totalMonths, int days)
    {
        int years = totalMonths / 12;
        int months = totalMonths % 12;

        var yearPart = years switch
        {
            0 => "",
            1 => "سنة واحدة",
            2 => "سنتين",
            3 => "ثلاث سنوات",
            4 => "أربع سنوات",
            5 => "خمس سنوات",
            6 => "ست سنوات",
            7 => "سبع سنوات",
            8 => "ثماني سنوات",
            9 => "تسع سنوات",
            10 => "عشر سنوات",
            _ => $"{years} سنة"
        };

        var monthPart = months switch
        {
            0 => "",
            1 => "شهر واحد",
            2 => "شهرين",
            3 => "ثلاثة شهور",
            4 => "أربعة شهور",
            5 => "خمسة شهور",
            6 => "ستة شهور",
            7 => "سبعة شهور",
            8 => "ثمانية شهور",
            9 => "تسعة شهور",
            10 => "عشرة شهور",
            11 => "أحد عشر شهراً",
            _ => ""
        };

        var dayPart = days switch
        {
            0 => "",
            1 => "يوم واحد",
            2 => "يومين",
            3 => "ثلاثة أيام",
            4 => "أربعة أيام",
            5 => "خمسة أيام",
            6 => "ستة أيام",
            7 => "سبعة أيام",
            8 => "ثمانية أيام",
            9 => "تسعة أيام",
            10 => "عشرة أيام",
            11 => "أحد عشر يوماً",
            12 => "اثنا عشر يوماً",
            13 => "ثلاثة عشر يوماً",
            14 => "أربعة عشر يوماً",
            15 => "خمسة عشر يوماً",
            16 => "ستة عشر يوماً",
            17 => "سبعة عشر يوماً",
            18 => "ثمانية عشر يوماً",
            19 => "تسعة عشر يوماً",
            20 => "عشرون يوماً",
            21 => "واحد وعشرون يوماً",
            22 => "اثنان وعشرون يوماً",
            23 => "ثلاثة وعشرون يوماً",
            24 => "أربعة وعشرون يوماً",
            25 => "خمسة وعشرون يوماً",
            26 => "ستة وعشرون يوماً",
            27 => "سبعة وعشرون يوماً",
            28 => "ثمانية وعشرون يوماً",
            29 => "تسعة وعشرون يوماً",
            30 => "ثلاثون يوماً",
            _ => ""
        };

        var parts = new List<string>();
        if (!string.IsNullOrEmpty(yearPart)) parts.Add(yearPart);
        if (!string.IsNullOrEmpty(monthPart)) parts.Add(monthPart);
        if (!string.IsNullOrEmpty(dayPart)) parts.Add(dayPart);

        return parts.Count > 0
            ? string.Join(" و ", parts)
            : "حديث الولادة";
    }

    // ────────────────────────────────────────────
    // 4. Get Additional Vaccination Survey
    // ────────────────────────────────────────────

    /// <inheritdoc />
    public async Task<ApiResponse<GetAdditionalVaccinationSurveyResponseDto>> GetAdditionalVaccinationSurveyAsync(
        Guid childId, Guid parentUserId)
    {
        try
        {
            var (parent, child, error) = await ValidateParentChildAsync<GetAdditionalVaccinationSurveyResponseDto>(childId, parentUserId);
            if (error != null) return error;

            // Calculate age in months to derive years
            var (ageMonths, _) = CalculateAgeInMonthsAndDays(child!.BirthDate);
            int ageYears = ageMonths / 12;

            // Only available for children 4+ years old
            if (ageYears < 4)
            {
                return ApiResponse<GetAdditionalVaccinationSurveyResponseDto>.FailureResponse(
                    "هذه الصفحة غير متاحة",
                    new List<string> { "التطعيمات الإضافية تظهر فقط للأطفال الذين بلغوا أربع سنوات فأكثر" }
                );
            }

            // Load only Additional category milestones
            var milestones = (await _unitOfWork.VaccinationMilestones.FindAsync(
                m => m.Category == "Additional" && m.IsActive
            )).OrderBy(m => m.SortOrder).ToList();

            // Load existing ChildVaccination records for additional milestones
            var milestoneIds = milestones.Select(m => m.Id).ToHashSet();
            var existingRecords = (await _unitOfWork.ChildVaccinations.FindAsync(
                cv => cv.ChildId == childId && milestoneIds.Contains(cv.VaccinationMilestoneId)
            )).ToDictionary(cv => cv.VaccinationMilestoneId);

            // Build milestone DTOs — simple enable/disable, no auto-select
            var milestoneDtos = milestones.Select(m =>
            {
                int milestoneAgeYears = m.AgeInMonths / 12;
                bool isDisabled = milestoneAgeYears > ageYears;

                // No auto-select: default is always false unless saved in DB
                bool isTaken = existingRecords.TryGetValue(m.Id, out var record)
                    ? record.IsTaken
                    : false;

                return new AdditionalVaccinationMilestoneDto
                {
                    MilestoneId = m.Id,
                    NameAr = m.NameAr,
                    NameEn = m.NameEn,
                    AgeInYears = milestoneAgeYears,
                    VaccinesAr = m.VaccinesAr,
                    VaccinesEn = m.VaccinesEn,
                    IsDisabled = isDisabled,
                    IsTaken = isTaken
                };
            }).ToList();

            var response = new GetAdditionalVaccinationSurveyResponseDto
            {
                ChildId = child.Id,
                ChildName = child.FullName.Split(' ')[0],
                ChildImageUrl = child.ProfileImageUrl,
                AgeYears = ageYears,
                AgeFormatted = FormatYearsArabic(ageYears),
                Milestones = milestoneDtos
            };

            return ApiResponse<GetAdditionalVaccinationSurveyResponseDto>.SuccessResponse(
                response,
                $"تم جلب التطعيمات الإضافية - {child.FullName}"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<GetAdditionalVaccinationSurveyResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب التطعيمات الإضافية",
                new List<string> { ex.Message }
            );
        }
    }

    // ────────────────────────────────────────────
    // 5. Submit Additional Vaccination Survey
    // ────────────────────────────────────────────

    /// <inheritdoc />
    public async Task<ApiResponse<SubmitVaccinationSurveyResponseDto>> SubmitAdditionalVaccinationSurveyAsync(
        SubmitVaccinationSurveyRequestDto request, Guid parentUserId)
    {
        try
        {
            var (parent, child, error) = await ValidateParentChildAsync<SubmitVaccinationSurveyResponseDto>(request.ChildId, parentUserId);
            if (error != null) return error;

            var (ageMonths, _) = CalculateAgeInMonthsAndDays(child!.BirthDate);
            int ageYears = ageMonths / 12;

            if (ageYears < 4)
            {
                return ApiResponse<SubmitVaccinationSurveyResponseDto>.FailureResponse(
                    "هذه الصفحة غير متاحة",
                    new List<string> { "التطعيمات الإضافية تظهر فقط للأطفال الذين بلغوا أربع سنوات فأكثر" }
                );
            }

            // Load milestones (Additional only) for validation
            var milestones = (await _unitOfWork.VaccinationMilestones.FindAsync(
                m => m.Category == "Additional" && m.IsActive
            )).ToDictionary(m => m.Id);

            // Validate: cannot mark a future milestone as taken
            foreach (var selection in request.Selections)
            {
                if (!milestones.TryGetValue(selection.MilestoneId, out var milestone))
                {
                    return ApiResponse<SubmitVaccinationSurveyResponseDto>.FailureResponse(
                        "تطعيم غير صالح",
                        new List<string> { $"التطعيم رقم {selection.MilestoneId} غير موجود في التطعيمات الإضافية" }
                    );
                }

                int milestoneAgeYears = milestone.AgeInMonths / 12;
                if (milestoneAgeYears > ageYears && selection.IsTaken)
                {
                    return ApiResponse<SubmitVaccinationSurveyResponseDto>.FailureResponse(
                        "لا يمكن تسجيل تطعيم مستقبلي",
                        new List<string> { $"لا يمكن تسجيل {milestone.NameAr} لأن عمر الطفل لم يصل بعد" }
                    );
                }
            }

            // Load existing records and upsert
            var milestoneIds = request.Selections.Select(s => s.MilestoneId).ToHashSet();
            var existingRecords = (await _unitOfWork.ChildVaccinations.FindAsync(
                cv => cv.ChildId == request.ChildId && milestoneIds.Contains(cv.VaccinationMilestoneId)
            )).ToDictionary(cv => cv.VaccinationMilestoneId);

            var now = DateTime.UtcNow;

            foreach (var selection in request.Selections)
            {
                if (existingRecords.TryGetValue(selection.MilestoneId, out var existing))
                {
                    existing.IsTaken = selection.IsTaken;
                    existing.UpdatedAt = now;
                    await _unitOfWork.ChildVaccinations.UpdateAsync(existing);
                }
                else
                {
                    var newRecord = new ChildVaccination
                    {
                        Id = Guid.NewGuid(),
                        ChildId = request.ChildId,
                        VaccinationMilestoneId = selection.MilestoneId,
                        IsTaken = selection.IsTaken,
                        RecordedAt = now,
                        UpdatedAt = now
                    };
                    await _unitOfWork.ChildVaccinations.AddAsync(newRecord);
                }
            }

            // Mark the additional survey as completed
            child!.HasCompletedAdditionalVaccinationSurvey = true;
            await _unitOfWork.Children.UpdateAsync(child);

            await _unitOfWork.SaveAsync();

            int takenCount = request.Selections.Count(s => s.IsTaken);

            var response = new SubmitVaccinationSurveyResponseDto
            {
                ChildId = request.ChildId,
                TotalMilestones = request.Selections.Count,
                TakenCount = takenCount,
                Message = $"تم تسجيل {takenCount} تطعيم إضافي من أصل {request.Selections.Count} بنجاح"
            };

            return ApiResponse<SubmitVaccinationSurveyResponseDto>.SuccessResponse(
                response,
                "تم حفظ التطعيمات الإضافية بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<SubmitVaccinationSurveyResponseDto>.FailureResponse(
                "حدث خطأ أثناء حفظ التطعيمات الإضافية",
                new List<string> { ex.Message }
            );
        }
    }

    // ────────────────────────────────────────────
    // Additional helper: Format years in Arabic
    // ────────────────────────────────────────────

    private static string FormatYearsArabic(int years) => years switch
    {
        1 => "سنة واحدة",
        2 => "سنتين",
        3 => "ثلاث سنوات",
        4 => "أربع سنوات",
        5 => "خمس سنوات",
        6 => "ست سنوات",
        7 => "سبع سنوات",
        8 => "ثماني سنوات",
        9 => "تسع سنوات",
        10 => "عشر سنوات",
        11 => "إحدى عشرة سنة",
        12 => "اثنتا عشرة سنة",
        13 => "ثلاث عشرة سنة",
        14 => "أربع عشرة سنة",
        15 => "خمس عشرة سنة",
        16 => "ست عشرة سنة",
        17 => "سبع عشرة سنة",
        18 => "ثماني عشرة سنة",
        _ => $"{years} سنة"
    };

    // ────────────────────────────────────────────
    // 6. Get Vaccination File
    // ────────────────────────────────────────────

    /// <inheritdoc />
    public async Task<ApiResponse<GetVaccinationFileResponseDto>> GetVaccinationFileAsync(
        Guid childId, Guid parentUserId)
    {
        try
        {
            var (parent, child, error) = await ValidateParentChildAsync<GetVaccinationFileResponseDto>(childId, parentUserId);
            if (error != null) return error;

            // Guard: must complete main survey first
            if (!child!.HasCompletedVaccinationSurvey)
            {
                return ApiResponse<GetVaccinationFileResponseDto>.FailureResponse(
                    "يجب إكمال استبيان التطعيمات أولاً",
                    new List<string> { "لا يمكن عرض ملف التطعيمات قبل إكمال الاستبيان الأساسي" }
                );
            }

            // Calculate age
            var (ageMonths, ageDays) = CalculateAgeInMonthsAndDays(child.BirthDate);
            int ageYears = ageMonths / 12;
            var today = DateTime.UtcNow.Date;

            // Load all milestones + existing records
            var allMilestones = (await _unitOfWork.VaccinationMilestones.GetAllAsync())
                .Where(m => m.IsActive)
                .OrderBy(m => m.SortOrder)
                .ToList();

            var existingRecords = (await _unitOfWork.ChildVaccinations.FindAsync(
                cv => cv.ChildId == childId
            )).ToDictionary(cv => cv.VaccinationMilestoneId);

            // ── Build Main Vaccination Cards ──
            var mainMilestones = allMilestones.Where(m => m.Category == "Main").ToList();
            var mainCards = new List<VaccinationCardDto>();

            foreach (var m in mainMilestones)
            {
                var dueDate = child.BirthDate.AddMonths(m.AgeInMonths);
                bool isTaken = existingRecords.TryGetValue(m.Id, out var record) && record.IsTaken;
                DateTime? completedDate = isTaken ? record!.UpdatedAt : null;

                var (label, labelEn, isDisabled, missedDays) =
                    AssignMainLabel(m.AgeInMonths, ageMonths, isTaken, dueDate, today);

                mainCards.Add(new VaccinationCardDto
                {
                    MilestoneId = m.Id,
                    NameAr = m.NameAr,
                    NameEn = m.NameEn,
                    VaccinesAr = m.VaccinesAr,
                    VaccinesEn = m.VaccinesEn,
                    Label = label,
                    LabelEn = labelEn,
                    DueDate = dueDate,
                    DueDateFormatted = FormatDateArabic(dueDate),
                    IsTaken = isTaken,
                    IsDisabled = isDisabled,
                    MissedSinceDays = missedDays,
                    CompletedDate = completedDate,
                    CompletedDateFormatted = completedDate.HasValue
                        ? $"تم في {FormatDateArabic(completedDate.Value)}"
                        : null
                });
            }

            var mainSection = new MainVaccinationSectionDto
            {
                AllCount = mainCards.Count,
                CurrentCount = mainCards.Count(c => c.LabelEn == "Current"),
                MissedCount = mainCards.Count(c => c.LabelEn == "Missed"),
                UpcomingCount = mainCards.Count(c => c.LabelEn == "Upcoming"),
                DoneCount = mainCards.Count(c => c.LabelEn == "Done"),
                Vaccinations = mainCards
            };

            // ── Build Additional Vaccination Cards ──
            var additionalSection = new AdditionalVaccinationSectionDto();

            if (ageYears >= 4)
            {
                additionalSection.IsAvailable = true;

                var additionalMilestones = allMilestones.Where(m => m.Category == "Additional").ToList();
                var additionalCards = new List<VaccinationCardDto>();

                foreach (var m in additionalMilestones)
                {
                    var dueDate = child.BirthDate.AddMonths(m.AgeInMonths);
                    bool isTaken = existingRecords.TryGetValue(m.Id, out var record) && record.IsTaken;
                    DateTime? completedDate = isTaken ? record!.UpdatedAt : null;

                    int milestoneAgeYears = m.AgeInMonths / 12;
                    var (label, labelEn, isDisabled) =
                        AssignAdditionalLabel(milestoneAgeYears, ageYears, isTaken);

                    additionalCards.Add(new VaccinationCardDto
                    {
                        MilestoneId = m.Id,
                        NameAr = m.NameAr,
                        NameEn = m.NameEn,
                        VaccinesAr = m.VaccinesAr,
                        VaccinesEn = m.VaccinesEn,
                        Label = label,
                        LabelEn = labelEn,
                        DueDate = dueDate,
                        DueDateFormatted = FormatDateArabic(dueDate),
                        IsTaken = isTaken,
                        IsDisabled = isDisabled,
                        MissedSinceDays = null,
                        CompletedDate = completedDate,
                        CompletedDateFormatted = completedDate.HasValue
                            ? $"تم في {FormatDateArabic(completedDate.Value)}"
                            : null
                    });
                }

                additionalSection.AllCount = additionalCards.Count;
                additionalSection.UpcomingCount = additionalCards.Count(c => c.LabelEn == "Upcoming");
                additionalSection.DoneCount = additionalCards.Count(c => c.LabelEn == "Done");
                additionalSection.Vaccinations = additionalCards;
            }
            else
            {
                additionalSection.IsAvailable = false;
            }

            var response = new GetVaccinationFileResponseDto
            {
                ChildId = child.Id,
                ChildName = child.FullName.Split(' ')[0],
                ChildImageUrl = child.ProfileImageUrl,
                AgeMonths = ageMonths,
                AgeDays = ageDays,
                AgeFormatted = FormatAgeArabic(ageMonths, ageDays),
                MainVaccinations = mainSection,
                AdditionalVaccinations = additionalSection
            };

            return ApiResponse<GetVaccinationFileResponseDto>.SuccessResponse(
                response,
                $"تم جلب ملف تطعيمات {child.FullName}"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<GetVaccinationFileResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب ملف التطعيمات",
                new List<string> { ex.Message }
            );
        }
    }

    // ────────────────────────────────────────────
    // Label Helpers
    // ────────────────────────────────────────────

    /// <summary>
    /// تحديد تصنيف التطعيم الأساسي (حالي/فائت/قادم/تم)
    /// </summary>
    private static (string label, string labelEn, bool isDisabled, int? missedDays)
        AssignMainLabel(int milestoneAgeMonths, int childAgeMonths, bool isTaken,
            DateTime dueDate, DateTime today)
    {
        if (isTaken)
            return ("تم", "Done", false, null);

        // Child is 18+ months → all untaken main milestones are missed
        if (childAgeMonths >= 18)
        {
            int missed = Math.Max(0, (int)(today - dueDate.Date).TotalDays);
            return ("فائت", "Missed", false, missed);
        }

        if (milestoneAgeMonths < childAgeMonths)
        {
            int missed = Math.Max(0, (int)(today - dueDate.Date).TotalDays);
            return ("فائت", "Missed", false, missed);
        }

        if (milestoneAgeMonths == childAgeMonths)
            return ("حالي", "Current", false, null);

        // milestoneAgeMonths > childAgeMonths
        return ("قادم", "Upcoming", true, null);
    }

    /// <summary>
    /// تحديد تصنيف التطعيم الإضافي (قادم/تم)
    /// </summary>
    private static (string label, string labelEn, bool isDisabled)
        AssignAdditionalLabel(int milestoneAgeYears, int childAgeYears, bool isTaken)
    {
        if (isTaken)
            return ("تم", "Done", false);

        if (milestoneAgeYears > childAgeYears)
            return ("قادم", "Upcoming", true);

        // milestoneAgeYears <= childAgeYears && !isTaken
        return ("قادم", "Upcoming", false);
    }

    // ────────────────────────────────────────────
    // Date Formatting Helper
    // ────────────────────────────────────────────

    /// <summary>
    /// تنسيق التاريخ بالعربي — e.g. "1 مايو 2026"
    /// </summary>
    private static string FormatDateArabic(DateTime date)
    {
        var monthName = date.Month switch
        {
            1 => "يناير",
            2 => "فبراير",
            3 => "مارس",
            4 => "أبريل",
            5 => "مايو",
            6 => "يونيو",
            7 => "يوليو",
            8 => "أغسطس",
            9 => "سبتمبر",
            10 => "أكتوبر",
            11 => "نوفمبر",
            12 => "ديسمبر",
            _ => ""
        };

        return $"{date.Day} {monthName} {date.Year}";
    }

    // ────────────────────────────────────────────
    // 7. Toggle Vaccination
    // ────────────────────────────────────────────

    /// <inheritdoc />
    public async Task<ApiResponse<ToggleVaccinationResponseDto>> ToggleVaccinationAsync(
        ToggleVaccinationRequestDto request, Guid parentUserId)
    {
        try
        {
            var (parent, child, error) = await ValidateParentChildAsync<ToggleVaccinationResponseDto>(request.ChildId, parentUserId);
            if (error != null) return error;

            // Guard: must complete main survey first
            if (!child!.HasCompletedVaccinationSurvey)
            {
                return ApiResponse<ToggleVaccinationResponseDto>.FailureResponse(
                    "يجب إكمال استبيان التطعيمات أولاً",
                    new List<string> { "لا يمكن تعديل التطعيمات قبل إكمال الاستبيان الأساسي" }
                );
            }

            // Load target milestone
            var targetMilestone = await _unitOfWork.VaccinationMilestones.GetByIdAsync(request.MilestoneId);
            if (targetMilestone == null || !targetMilestone.IsActive)
            {
                return ApiResponse<ToggleVaccinationResponseDto>.FailureResponse(
                    "تطعيم غير موجود",
                    new List<string> { $"التطعيم رقم {request.MilestoneId} غير موجود" }
                );
            }

            // Calculate age
            var (ageMonths, _) = CalculateAgeInMonthsAndDays(child.BirthDate);
            int ageYears = ageMonths / 12;

            // ── Category-specific validation ──
            if (targetMilestone.Category == "Main")
            {
                // Age validation: cannot toggle a future (disabled) milestone
                if (ageMonths < 18 && targetMilestone.AgeInMonths > ageMonths)
                {
                    return ApiResponse<ToggleVaccinationResponseDto>.FailureResponse(
                        "لا يمكن تعديل تطعيم مستقبلي",
                        new List<string> { $"لا يمكن تعديل {targetMilestone.NameAr} لأن عمر الطفل لم يصل بعد" }
                    );
                }

                // Load all main milestones for prerequisite chain
                var mainMilestones = (await _unitOfWork.VaccinationMilestones.FindAsync(
                    m => m.Category == "Main" && m.IsActive
                )).OrderBy(m => m.SortOrder).ToList();

                // Load all existing records for this child's main milestones
                var mainMilestoneIds = mainMilestones.Select(m => m.Id).ToHashSet();
                var existingRecords = (await _unitOfWork.ChildVaccinations.FindAsync(
                    cv => cv.ChildId == request.ChildId && mainMilestoneIds.Contains(cv.VaccinationMilestoneId)
                )).ToDictionary(cv => cv.VaccinationMilestoneId);

                if (request.IsTaken)
                {
                    // ── Rule 1: Cannot mark as taken if prerequisite is not taken ──
                    var prerequisite = mainMilestones
                        .Where(m => m.SortOrder == targetMilestone.SortOrder - 1)
                        .FirstOrDefault();

                    if (prerequisite != null)
                    {
                        bool prerequisiteTaken = existingRecords.TryGetValue(prerequisite.Id, out var prereqRecord)
                            && prereqRecord.IsTaken;

                        if (!prerequisiteTaken)
                        {
                            return ApiResponse<ToggleVaccinationResponseDto>.FailureResponse(
                                "متطلب مسبق غير مكتمل",
                                new List<string> { $"لا يمكن أخذ ({targetMilestone.NameAr}) قبل أخذ ({prerequisite.NameAr})" }
                            );
                        }
                    }
                }
                else
                {
                    // ── Rule 2: Cannot unmark if a dependent vaccination is taken ──
                    var dependent = mainMilestones
                        .Where(m => m.SortOrder == targetMilestone.SortOrder + 1)
                        .FirstOrDefault();

                    if (dependent != null)
                    {
                        bool dependentTaken = existingRecords.TryGetValue(dependent.Id, out var depRecord)
                            && depRecord.IsTaken;

                        if (dependentTaken)
                        {
                            return ApiResponse<ToggleVaccinationResponseDto>.FailureResponse(
                                "لا يمكن إزالة هذا التطعيم",
                                new List<string> { $"لا يمكن إزالة {targetMilestone.NameAr} لأن هناك تطعيم أحدث يعتمد عليه ({dependent.NameAr})." }
                            );
                        }
                    }
                }
            }
            else if (targetMilestone.Category == "Additional")
            {
                // Age gate: child must be >= 4 years
                if (ageYears < 4)
                {
                    return ApiResponse<ToggleVaccinationResponseDto>.FailureResponse(
                        "التطعيمات الإضافية غير متاحة",
                        new List<string> { "التطعيمات الإضافية تظهر فقط للأطفال الذين بلغوا أربع سنوات فأكثر" }
                    );
                }

                // Cannot toggle a disabled (future) additional milestone
                int milestoneAgeYears = targetMilestone.AgeInMonths / 12;
                if (milestoneAgeYears > ageYears)
                {
                    return ApiResponse<ToggleVaccinationResponseDto>.FailureResponse(
                        "لا يمكن تعديل تطعيم مستقبلي",
                        new List<string> { $"لا يمكن تعديل {targetMilestone.NameAr} لأن عمر الطفل لم يصل بعد" }
                    );
                }
            }

            // ── Upsert the record ──
            var now = DateTime.UtcNow;
            var existingRecord = await _unitOfWork.ChildVaccinations.GetFirstOrDefaultAsync(
                cv => cv.ChildId == request.ChildId && cv.VaccinationMilestoneId == request.MilestoneId
            );

            if (existingRecord != null)
            {
                existingRecord.IsTaken = request.IsTaken;
                existingRecord.UpdatedAt = now;
                await _unitOfWork.ChildVaccinations.UpdateAsync(existingRecord);
            }
            else
            {
                var newRecord = new ChildVaccination
                {
                    Id = Guid.NewGuid(),
                    ChildId = request.ChildId,
                    VaccinationMilestoneId = request.MilestoneId,
                    IsTaken = request.IsTaken,
                    RecordedAt = now,
                    UpdatedAt = now
                };
                await _unitOfWork.ChildVaccinations.AddAsync(newRecord);
            }

            await _unitOfWork.SaveAsync();

            var actionText = request.IsTaken ? "تم تسجيل" : "تم إلغاء تسجيل";
            var response = new ToggleVaccinationResponseDto
            {
                ChildId = request.ChildId,
                MilestoneId = request.MilestoneId,
                IsTaken = request.IsTaken,
                MilestoneNameAr = targetMilestone.NameAr,
                Message = $"{actionText} {targetMilestone.NameAr} بنجاح"
            };

            return ApiResponse<ToggleVaccinationResponseDto>.SuccessResponse(
                response,
                $"{actionText} {targetMilestone.NameAr}"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<ToggleVaccinationResponseDto>.FailureResponse(
                "حدث خطأ أثناء تعديل حالة التطعيم",
                new List<string> { ex.Message }
            );
        }
    }
}
