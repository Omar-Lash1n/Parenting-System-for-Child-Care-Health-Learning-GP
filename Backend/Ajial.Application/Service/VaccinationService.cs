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
                ProfileImageUrl = child.ProfileImageUrl
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
}
