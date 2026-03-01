using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Vaccination;

namespace Ajial.Application.Interfaces;

public interface IVaccinationService
{
    /// <summary>
    /// صفحة الترحيب - Get vaccination welcome page data (child name + image)
    /// يتم استدعاؤها عند دخول ولي الأمر على ملف التطعيمات لطفل معين
    /// </summary>
    Task<ApiResponse<VaccinationWelcomeResponseDto>> GetVaccinationWelcomeAsync(Guid childId, Guid parentUserId);

    /// <summary>
    /// استبيان التطعيمات - Get vaccination survey with milestones adapted to child's age
    /// يرجع التطعيمات السبعة مع حالة كل واحد حسب عمر الطفل
    /// </summary>
    Task<ApiResponse<GetVaccinationSurveyResponseDto>> GetVaccinationSurveyAsync(Guid childId, Guid parentUserId);

    /// <summary>
    /// تقديم استبيان التطعيمات - Submit (save) the parent's survey selections
    /// حفظ اختيارات ولي الأمر في الاستبيان
    /// </summary>
    Task<ApiResponse<SubmitVaccinationSurveyResponseDto>> SubmitVaccinationSurveyAsync(
        SubmitVaccinationSurveyRequestDto request, Guid parentUserId);

    /// <summary>
    /// استبيان التطعيمات الإضافية - Get additional vaccination survey (4-15 year milestones)
    /// يظهر فقط للأطفال أعمارهم 4 سنوات فأكثر
    /// </summary>
    Task<ApiResponse<GetAdditionalVaccinationSurveyResponseDto>> GetAdditionalVaccinationSurveyAsync(
        Guid childId, Guid parentUserId);

    /// <summary>
    /// تقديم استبيان التطعيمات الإضافية - Submit additional vaccination survey
    /// </summary>
    Task<ApiResponse<SubmitVaccinationSurveyResponseDto>> SubmitAdditionalVaccinationSurveyAsync(
        SubmitVaccinationSurveyRequestDto request, Guid parentUserId);
}
