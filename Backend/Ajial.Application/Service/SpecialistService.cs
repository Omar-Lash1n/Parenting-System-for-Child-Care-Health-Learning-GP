using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Specialist;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Service;

public class SpecialistService : ISpecialistService
{
    private readonly IUnitOfWork _unitOfWork;

    public SpecialistService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    /// <summary>
    /// Get all registered specialists with full profile data
    /// </summary>
    public async Task<ApiResponse<IEnumerable<SpecialistDto>>> GetAllSpecialistsAsync()
    {
        try
        {
            var specialists = await _unitOfWork.Specialists.GetAllAsync();

            var result = new List<SpecialistDto>();

            foreach (var specialist in specialists)
            {
                // Load the linked user
                var user = await _unitOfWork.Users.GetByIdAsync(specialist.UserId);
                if (user == null) continue;

                result.Add(MapToDto(specialist, user));
            }

            return ApiResponse<IEnumerable<SpecialistDto>>.SuccessResponse(
                result,
                $"تم جلب {result.Count} أخصائي"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<IEnumerable<SpecialistDto>>.FailureResponse(
                "حدث خطأ أثناء جلب بيانات الأخصائيين",
                new List<string> { ex.Message }
            );
        }
    }

    /// <summary>
    /// Approve or reject a pending specialist
    /// </summary>
    public async Task<ApiResponse<SpecialistDto>> UpdateSpecialistStatusAsync(UpdateSpecialistStatusRequest request)
    {
        try
        {
            // Validate status value
            if (!Enum.IsDefined(typeof(SpecialistStatus), request.Status))
            {
                return ApiResponse<SpecialistDto>.FailureResponse(
                    "حالة غير صحيحة",
                    new List<string> { "الحالة يجب أن تكون 2 (موافقة) أو 3 (رفض)" }
                );
            }

            var newStatus = (SpecialistStatus)request.Status;

            // Only allow Approved or Rejected
            if (newStatus != SpecialistStatus.Approved && newStatus != SpecialistStatus.Rejected)
            {
                return ApiResponse<SpecialistDto>.FailureResponse(
                    "حالة غير صحيحة",
                    new List<string> { "الحالة يجب أن تكون 2 (موافقة) أو 3 (رفض)" }
                );
            }

            // Find specialist
            var specialist = await _unitOfWork.Specialists.GetByIdAsync(request.SpecialistId);
            if (specialist == null)
            {
                return ApiResponse<SpecialistDto>.FailureResponse(
                    "الأخصائي غير موجود",
                    new List<string> { "لم يتم العثور على الأخصائي بهذا المعرف" }
                );
            }

            if (newStatus == SpecialistStatus.Rejected && string.IsNullOrWhiteSpace(request.RejectionReason))
            {
                return ApiResponse<SpecialistDto>.FailureResponse(
                    "سبب الرفض مطلوب",
                    new List<string> { "سبب الرفض مطلوب" }
                );
            }

            var fromStatus = specialist.Status;
            var now = DateTime.UtcNow;

            // Update status
            specialist.Status = newStatus;
            specialist.UpdatedAt = now;
            specialist.ReviewedAt = now;
            specialist.ReviewedByUserId = Guid.Empty;
            specialist.RejectionReason = newStatus == SpecialistStatus.Rejected
                ? request.RejectionReason?.Trim()
                : null;

            await _unitOfWork.SpecialistStatusHistories.AddAsync(new SpecialistStatusHistory
            {
                Id = Guid.NewGuid(),
                SpecialistId = specialist.Id,
                FromStatus = fromStatus,
                ToStatus = newStatus,
                Reason = specialist.RejectionReason,
                ChangedByUserId = Guid.Empty,
                ChangedAt = now
            });

            await _unitOfWork.Specialists.UpdateAsync(specialist);
            await _unitOfWork.SaveChangesAsync();

            // Load user for response
            var user = await _unitOfWork.Users.GetByIdAsync(specialist.UserId);
            if (user == null)
            {
                return ApiResponse<SpecialistDto>.FailureResponse(
                    "خطأ في البيانات",
                    new List<string> { "لم يتم العثور على بيانات المستخدم المرتبط" }
                );
            }

            var statusLabel = newStatus == SpecialistStatus.Approved ? "تمت الموافقة" : "تم الرفض";

            return ApiResponse<SpecialistDto>.SuccessResponse(
                MapToDto(specialist, user),
                $"{statusLabel} على تسجيل الأخصائي {user.FullName}"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<SpecialistDto>.FailureResponse(
                "حدث خطأ أثناء تحديث حالة الأخصائي",
                new List<string> { ex.Message }
            );
        }
    }

    // ─── Helper ────────────────────────────────────────────────────────────────

    private static SpecialistDto MapToDto(Specialist specialist, User user) => new()
    {
        SpecialistId = specialist.Id,
        UserId = user.Id,
        FullName = user.FullName,
        Username = user.Username,
        Email = user.Email,
        Phone = specialist.Phone,
        Specialization = specialist.Specialization,
        PracticeLicenseNumber = specialist.PracticeLicenseNumber,
        Status = specialist.Status.ToString(),
        IdFrontImageUrl = specialist.IdFrontImageUrl,
        IdBackImageUrl = specialist.IdBackImageUrl,
        SpecializationCertificateImageUrl = specialist.SpecializationCertificateImageUrl,
        PracticeLicenseImageUrl = specialist.PracticeLicenseImageUrl,
        UnionCardImageUrl = specialist.UnionCardImageUrl,
        PersonalPhotoUrl = specialist.PersonalPhotoUrl,
        CreatedAt = specialist.CreatedAt,
        UpdatedAt = specialist.UpdatedAt
    };
}
