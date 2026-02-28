using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Vaccination;

namespace Ajial.Application.Interfaces;

public interface IVaccinationService
{
    /// <summary>
    /// صفحة الترحيب - Get vaccination welcome page data (child name + image)
    /// يتم استدعاؤها عند دخول ولي الأمر على ملف التطعيمات لطفل معين
    /// </summary>
    /// <param name="childId">معرّف الطفل</param>
    /// <param name="parentUserId">معرّف ولي الأمر (من JWT)</param>
    Task<ApiResponse<VaccinationWelcomeResponseDto>> GetVaccinationWelcomeAsync(Guid childId, Guid parentUserId);
}
