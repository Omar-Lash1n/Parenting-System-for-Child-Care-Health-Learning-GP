using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Vaccination;
using Ajial.Application.Interfaces;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Services;

public class VaccinationService : IVaccinationService
{
    private readonly IUnitOfWork _unitOfWork;

    public VaccinationService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    /// <inheritdoc />
    public async Task<ApiResponse<VaccinationWelcomeResponseDto>> GetVaccinationWelcomeAsync(
        Guid childId, Guid parentUserId)
    {
        try
        {
            // Step 1: Verify that the parent exists
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(
                p => p.UserId == parentUserId
            );

            if (parent == null)
            {
                return ApiResponse<VaccinationWelcomeResponseDto>.FailureResponse(
                    "ولي الأمر غير موجود",
                    new List<string> { "لم يتم العثور على حساب ولي الأمر" }
                );
            }

            // Step 2: Get the child and verify ownership
            var child = await _unitOfWork.Children.GetByIdAsync(childId);

            if (child == null)
            {
                return ApiResponse<VaccinationWelcomeResponseDto>.FailureResponse(
                    "الطفل غير موجود",
                    new List<string> { "لم يتم العثور على بيانات الطفل" }
                );
            }

            // Step 3: Verify that this child belongs to the authenticated parent
            if (child.ParentId != parent.Id)
            {
                return ApiResponse<VaccinationWelcomeResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "هذا الطفل لا ينتمي إلى حسابك" }
                );
            }

            // Step 4: Build the welcome response
            var response = new VaccinationWelcomeResponseDto
            {
                ChildId = child.Id,
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
}
