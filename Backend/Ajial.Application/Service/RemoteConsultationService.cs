using System.Text.Json;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.RemoteConsultation;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Service;

public class RemoteConsultationService : IRemoteConsultationService
{
    private readonly IUnitOfWork _unitOfWork;

    public RemoteConsultationService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    // ── Doctor endpoints ──────────────────────────────────────────────────────

    public async Task<ApiResponse<List<RemoteConsultationCardResponse>>> GetDoctorConsultationsAsync(Guid userId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.UserId == userId);
            if (specialist == null)
                return ApiResponse<List<RemoteConsultationCardResponse>>.FailureResponse("لم يتم العثور على بيانات الطبيب");

            var items = (await _unitOfWork.RemoteConsultations.FindAsync(c => c.SpecialistId == specialist.Id))
                .OrderByDescending(c => c.SubmittedAt ?? c.CreatedAt)
                .Select(MapToCard)
                .ToList();

            return ApiResponse<List<RemoteConsultationCardResponse>>.SuccessResponse(items, "تم جلب بيانات الكشف عن بعد بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<List<RemoteConsultationCardResponse>>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<RemoteConsultationDetailResponse>> GetConsultationDetailAsync(Guid consultationId, Guid userId)
    {
        try
        {
            var (rc, error) = await ResolveForDoctor<RemoteConsultationDetailResponse>(consultationId, userId);
            if (error != null) return error;

            return ApiResponse<RemoteConsultationDetailResponse>.SuccessResponse(MapToDetail(rc!), "تم جلب التفاصيل بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<RemoteConsultationDetailResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<RemoteConsultationStatusChangeResponse>> CreateConsultationAsync(Guid userId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.UserId == userId);
            if (specialist == null)
                return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("لم يتم العثور على بيانات الطبيب");

            if (specialist.Status != SpecialistStatus.Approved)
                return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("لا يمكن إضافة خدمة كشف عن بعد قبل قبول طلب التسجيل");

            var rc = new RemoteConsultation
            {
                Id = Guid.NewGuid(),
                SpecialistId = specialist.Id,
                Status = RemoteConsultationStatus.Draft,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.RemoteConsultations.AddAsync(rc);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<RemoteConsultationStatusChangeResponse>.SuccessResponse(
                MapToStatusChange(rc), "تم إنشاء مسودة الكشف عن بعد، يمكنك إضافة البيانات الآن");
        }
        catch (Exception ex)
        {
            return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<RemoteConsultationDetailResponse>> UpdateConsultationAsync(Guid consultationId, Guid userId, UpdateRemoteConsultationRequest request)
    {
        try
        {
            var (rc, error) = await ResolveForDoctor<RemoteConsultationDetailResponse>(consultationId, userId);
            if (error != null) return error;

            if (!IsDraftOrRejected(rc!.Status))
                return ApiResponse<RemoteConsultationDetailResponse>.FailureResponse("لا يمكن تعديل البيانات في الحالة الحالية");

            if (request.SessionPrice.HasValue) rc!.SessionPrice = request.SessionPrice.Value;
            if (request.SessionDurationMinutes.HasValue) rc!.SessionDurationMinutes = request.SessionDurationMinutes.Value;
            if (request.WaitingPeriodMinutes.HasValue) rc!.WaitingPeriodMinutes = request.WaitingPeriodMinutes.Value;
            if (request.WorkingHoursJson != null)
            {
                if (!IsValidJson(request.WorkingHoursJson))
                    return ApiResponse<RemoteConsultationDetailResponse>.FailureResponse(
                        "خطأ في البيانات المدخلة", new List<string> { "صيغة مواعيد العمل غير صحيحة" });
                rc!.WorkingHoursJson = request.WorkingHoursJson;
            }

            rc!.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.RemoteConsultations.UpdateAsync(rc);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<RemoteConsultationDetailResponse>.SuccessResponse(MapToDetail(rc), "تم تحديث بيانات الكشف عن بعد بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<RemoteConsultationDetailResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<RemoteConsultationStatusChangeResponse>> SubmitConsultationAsync(Guid consultationId, Guid userId)
    {
        try
        {
            var (rc, error) = await ResolveForDoctor<RemoteConsultationStatusChangeResponse>(consultationId, userId);
            if (error != null) return error;

            if (!IsDraftOrRejected(rc!.Status))
                return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("لا يمكن تقديم الطلب في الحالة الحالية");

            var missing = GetSubmitValidationErrors(rc);
            if (missing.Count > 0)
                return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("يوجد بيانات مطلوبة غير مكتملة", missing);

            rc.Status = RemoteConsultationStatus.Pending;
            rc.SubmittedAt = DateTime.UtcNow;
            rc.RejectionReason = null;
            rc.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.RemoteConsultations.UpdateAsync(rc);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<RemoteConsultationStatusChangeResponse>.SuccessResponse(
                MapToStatusChange(rc), "تم ارسال بيانات الكشف بنجاح!");
        }
        catch (Exception ex)
        {
            return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<RemoteConsultationStatusChangeResponse>> CancelConsultationAsync(Guid consultationId, Guid userId)
    {
        try
        {
            var (rc, error) = await ResolveForDoctor<RemoteConsultationStatusChangeResponse>(consultationId, userId);
            if (error != null) return error;

            if (rc!.Status != RemoteConsultationStatus.Draft && rc.Status != RemoteConsultationStatus.Pending && rc.Status != RemoteConsultationStatus.Rejected)
                return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("لا يمكن إلغاء الطلب في الحالة الحالية");

            rc.Status = RemoteConsultationStatus.Cancelled;
            rc.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.RemoteConsultations.UpdateAsync(rc);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<RemoteConsultationStatusChangeResponse>.SuccessResponse(
                MapToStatusChange(rc), "تم إلغاء طلب إضافة الكشف عن بعد");
        }
        catch (Exception ex)
        {
            return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<RemoteConsultationStatusChangeResponse>> StartEditConsultationAsync(Guid consultationId, Guid userId)
    {
        try
        {
            var (rc, error) = await ResolveForDoctor<RemoteConsultationStatusChangeResponse>(consultationId, userId);
            if (error != null) return error;

            if (rc!.Status != RemoteConsultationStatus.Pending)
                return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("لا يمكن تعديل الطلب - الطلب ليس قيد المراجعة");

            rc.Status = RemoteConsultationStatus.Draft;
            rc.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.RemoteConsultations.UpdateAsync(rc);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<RemoteConsultationStatusChangeResponse>.SuccessResponse(
                MapToStatusChange(rc), "يمكنك الآن تعديل البيانات وإعادة تقديم الطلب");
        }
        catch (Exception ex)
        {
            return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── Admin endpoints ───────────────────────────────────────────────────────

    public async Task<ApiResponse<AdminRemoteConsultationListResponse>> GetConsultationsForAdminAsync(int? status, int page, int pageSize)
    {
        try
        {
            var normalizedPage = Math.Max(page, 1);
            var normalizedSize = Math.Clamp(pageSize, 1, 100);

            var all = await _unitOfWork.RemoteConsultations.GetAllAsync();
            var query = all.AsEnumerable();

            if (status.HasValue)
            {
                if (!Enum.IsDefined(typeof(RemoteConsultationStatus), status.Value))
                    return ApiResponse<AdminRemoteConsultationListResponse>.FailureResponse("حالة غير صحيحة");

                query = query.Where(c => (int)c.Status == status.Value);
            }

            var ordered = query.OrderByDescending(c => c.SubmittedAt ?? c.CreatedAt).ToList();
            var total = ordered.Count;
            var pageItems = ordered.Skip((normalizedPage - 1) * normalizedSize).Take(normalizedSize).ToList();

            var items = new List<AdminRemoteConsultationListItemDto>();
            foreach (var rc in pageItems)
            {
                var specialist = await _unitOfWork.Specialists.GetByIdAsync(rc.SpecialistId);
                var user = specialist != null ? await _unitOfWork.Users.GetByIdAsync(specialist.UserId) : null;
                items.Add(new AdminRemoteConsultationListItemDto
                {
                    ConsultationId = rc.Id,
                    DoctorName = user?.FullName ?? string.Empty,
                    Status = GetStatusKey(rc.Status),
                    StatusAr = GetStatusArabicLabel(rc.Status),
                    SubmittedAt = rc.SubmittedAt
                });
            }

            return ApiResponse<AdminRemoteConsultationListResponse>.SuccessResponse(new AdminRemoteConsultationListResponse
            {
                TotalCount = total,
                Page = normalizedPage,
                PageSize = normalizedSize,
                Items = items
            }, "تم جلب قائمة الكشف عن بعد بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<AdminRemoteConsultationListResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<AdminRemoteConsultationDetailResponse>> GetConsultationForAdminAsync(Guid consultationId)
    {
        try
        {
            var rc = await _unitOfWork.RemoteConsultations.GetByIdAsync(consultationId);
            if (rc == null)
                return ApiResponse<AdminRemoteConsultationDetailResponse>.FailureResponse("لم يتم العثور على طلب الكشف عن بعد");

            var specialist = await _unitOfWork.Specialists.GetByIdAsync(rc.SpecialistId);
            var user = specialist != null ? await _unitOfWork.Users.GetByIdAsync(specialist.UserId) : null;

            return ApiResponse<AdminRemoteConsultationDetailResponse>.SuccessResponse(new AdminRemoteConsultationDetailResponse
            {
                ConsultationId = rc.Id,
                SpecialistId = rc.SpecialistId,
                DoctorName = user?.FullName ?? string.Empty,
                Status = GetStatusKey(rc.Status),
                StatusAr = GetStatusArabicLabel(rc.Status),
                SubmittedAt = rc.SubmittedAt,
                RejectionReason = rc.RejectionReason,
                SessionPrice = rc.SessionPrice,
                SessionDurationMinutes = rc.SessionDurationMinutes,
                WaitingPeriodMinutes = rc.WaitingPeriodMinutes,
                WorkingHoursJson = rc.WorkingHoursJson
            }, "تم جلب تفاصيل الكشف عن بعد بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<AdminRemoteConsultationDetailResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<RemoteConsultationStatusChangeResponse>> ApproveConsultationAsync(Guid consultationId, Guid adminUserId)
    {
        try
        {
            var rc = await _unitOfWork.RemoteConsultations.GetByIdAsync(consultationId);
            if (rc == null)
                return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("لم يتم العثور على طلب الكشف عن بعد");

            if (rc.Status != RemoteConsultationStatus.Pending)
                return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("لا يمكن قبول الطلب - ليس قيد المراجعة");

            rc.Status = RemoteConsultationStatus.Approved;
            rc.ReviewedAt = DateTime.UtcNow;
            rc.ReviewedByUserId = adminUserId;
            rc.RejectionReason = null;
            rc.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.RemoteConsultations.UpdateAsync(rc);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<RemoteConsultationStatusChangeResponse>.SuccessResponse(
                MapToStatusChange(rc), "تم قبول طلب الكشف عن بعد بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<RemoteConsultationStatusChangeResponse>> RejectConsultationAsync(Guid consultationId, Guid adminUserId, RejectRemoteConsultationRequest request)
    {
        try
        {
            var rc = await _unitOfWork.RemoteConsultations.GetByIdAsync(consultationId);
            if (rc == null)
                return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("لم يتم العثور على طلب الكشف عن بعد");

            if (rc.Status != RemoteConsultationStatus.Pending)
                return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("لا يمكن رفض الطلب - ليس قيد المراجعة");

            rc.Status = RemoteConsultationStatus.Rejected;
            rc.RejectionReason = request.Reason;
            rc.ReviewedAt = DateTime.UtcNow;
            rc.ReviewedByUserId = adminUserId;
            rc.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.RemoteConsultations.UpdateAsync(rc);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<RemoteConsultationStatusChangeResponse>.SuccessResponse(
                MapToStatusChange(rc), "تم رفض طلب الكشف عن بعد");
        }
        catch (Exception ex)
        {
            return ApiResponse<RemoteConsultationStatusChangeResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(RemoteConsultation? rc, ApiResponse<T>? error)> ResolveForDoctor<T>(Guid consultationId, Guid userId)
    {
        var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.UserId == userId);
        if (specialist == null)
            return (null, ApiResponse<T>.FailureResponse("لم يتم العثور على بيانات الطبيب"));

        var rc = await _unitOfWork.RemoteConsultations.GetByIdAsync(consultationId);
        if (rc == null)
            return (null, ApiResponse<T>.FailureResponse("لم يتم العثور على طلب الكشف عن بعد"));

        if (rc.SpecialistId != specialist.Id)
            return (null, ApiResponse<T>.FailureResponse("غير مصرح - هذا الطلب لا يخصك"));

        return (rc, null);
    }

    private static bool IsDraftOrRejected(RemoteConsultationStatus status) =>
        status == RemoteConsultationStatus.Draft || status == RemoteConsultationStatus.Rejected;

    private static List<string> GetSubmitValidationErrors(RemoteConsultation rc)
    {
        var errors = new List<string>();
        if (!rc.SessionPrice.HasValue) errors.Add("سعر الجلسة مطلوب");
        if (!rc.SessionDurationMinutes.HasValue) errors.Add("مدة الجلسة مطلوبة");
        if (!rc.WaitingPeriodMinutes.HasValue) errors.Add("فترة الانتظار بين كل جلسة مطلوبة");
        if (string.IsNullOrWhiteSpace(rc.WorkingHoursJson)) errors.Add("مواعيد العمل مطلوبة");
        return errors;
    }

    private static bool IsValidJson(string json)
    {
        try { JsonDocument.Parse(json); return true; }
        catch { return false; }
    }

    private static RemoteConsultationCardResponse MapToCard(RemoteConsultation rc) => new()
    {
        ConsultationId = rc.Id,
        Status = GetStatusKey(rc.Status),
        StatusAr = GetStatusArabicLabel(rc.Status),
        SubmittedAt = rc.SubmittedAt,
        RejectionReason = rc.RejectionReason,
        CanEdit = IsDraftOrRejected(rc.Status),
        CanCancel = rc.Status is RemoteConsultationStatus.Draft or RemoteConsultationStatus.Pending or RemoteConsultationStatus.Rejected,
        CanSubmit = IsDraftOrRejected(rc.Status)
    };

    private static RemoteConsultationDetailResponse MapToDetail(RemoteConsultation rc) => new()
    {
        ConsultationId = rc.Id,
        Status = GetStatusKey(rc.Status),
        StatusAr = GetStatusArabicLabel(rc.Status),
        SubmittedAt = rc.SubmittedAt,
        RejectionReason = rc.RejectionReason,
        SessionPrice = rc.SessionPrice,
        SessionDurationMinutes = rc.SessionDurationMinutes,
        WaitingPeriodMinutes = rc.WaitingPeriodMinutes,
        WorkingHoursJson = rc.WorkingHoursJson,
        CanEdit = IsDraftOrRejected(rc.Status),
        CanCancel = rc.Status is RemoteConsultationStatus.Draft or RemoteConsultationStatus.Pending or RemoteConsultationStatus.Rejected,
        CanSubmit = IsDraftOrRejected(rc.Status)
    };

    private static RemoteConsultationStatusChangeResponse MapToStatusChange(RemoteConsultation rc) => new()
    {
        ConsultationId = rc.Id,
        Status = GetStatusKey(rc.Status),
        StatusAr = GetStatusArabicLabel(rc.Status)
    };

    private static string GetStatusKey(RemoteConsultationStatus s) => s switch
    {
        RemoteConsultationStatus.Draft => "draft",
        RemoteConsultationStatus.Pending => "pending",
        RemoteConsultationStatus.Approved => "approved",
        RemoteConsultationStatus.Rejected => "rejected",
        RemoteConsultationStatus.Cancelled => "cancelled",
        _ => "unknown"
    };

    private static string GetStatusArabicLabel(RemoteConsultationStatus s) => s switch
    {
        RemoteConsultationStatus.Draft => "مسودة",
        RemoteConsultationStatus.Pending => "جاري المراجعة",
        RemoteConsultationStatus.Approved => "تمت الموافقة",
        RemoteConsultationStatus.Rejected => "لم يتم القبول",
        RemoteConsultationStatus.Cancelled => "ملغي",
        _ => "غير معروف"
    };
}
