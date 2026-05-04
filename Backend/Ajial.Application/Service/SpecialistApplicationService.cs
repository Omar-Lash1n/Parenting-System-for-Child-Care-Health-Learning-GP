using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.SpecialistApplication;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;
using Microsoft.AspNetCore.Http;

namespace Ajial.Application.Service;

public class SpecialistApplicationService : ISpecialistApplicationService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IImageService _imageService;

    public SpecialistApplicationService(IUnitOfWork unitOfWork, IImageService imageService)
    {
        _unitOfWork = unitOfWork;
        _imageService = imageService;
    }

    public async Task<ApiResponse<CurrentApplicationCardResponse>> GetCurrentApplicationAsync(Guid userId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.UserId == userId);
            if (specialist == null)
            {
                return ApiResponse<CurrentApplicationCardResponse>.FailureResponse(
                    "لم يتم العثور على الطلب",
                    new List<string> { "لم يتم العثور على بيانات الأخصائي لهذا المستخدم" });
            }

            return ApiResponse<CurrentApplicationCardResponse>.SuccessResponse(
                new CurrentApplicationCardResponse
                {
                    ApplicationId = specialist.Id,
                    SpecialistId = specialist.Id,
                    SpecialtyName = specialist.Specialization,
                    SubmittedAt = specialist.SubmittedAt,
                    Status = GetStatusKey(specialist.Status),
                    StatusAr = GetStatusArabicLabel(specialist.Status),
                    RejectionReason = specialist.RejectionReason,
                    CanView = true,
                    CanEdit = CanEdit(specialist.Status),
                    CanCancel = CanCancel(specialist.Status),
                    CanCreateNew = CanCreateNew(specialist.Status),
                    PersonalPhotoUrl = specialist.PersonalPhotoUrl
                },
                "تم جلب بيانات الطلب بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<CurrentApplicationCardResponse>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<ApplicationDetailsResponse>> GetApplicationDetailsAsync(Guid applicationId, Guid userId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetByIdAsync(applicationId);
            var ownership = ValidateOwnership<ApplicationDetailsResponse>(specialist, userId);
            if (ownership != null)
            {
                return ownership;
            }

            return ApiResponse<ApplicationDetailsResponse>.SuccessResponse(
                await MapApplicationDetailsAsync(specialist!),
                "تم جلب تفاصيل الطلب بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ApplicationDetailsResponse>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<StatusChangeResponse>> SubmitApplicationAsync(Guid applicationId, Guid userId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetByIdAsync(applicationId);
            var ownership = ValidateOwnership<StatusChangeResponse>(specialist, userId);
            if (ownership != null)
            {
                return ownership;
            }

            if (specialist!.Status != SpecialistStatus.Draft)
            {
                return ApiResponse<StatusChangeResponse>.FailureResponse(
                    "لا يمكن تقديم الطلب - الحالة الحالية لا تسمح بذلك");
            }

            var missing = GetSubmitValidationErrors(specialist);
            if (missing.Count > 0)
            {
                return ApiResponse<StatusChangeResponse>.FailureResponse(
                    "لا يمكن تقديم الطلب في هذه الحالة",
                    missing);
            }

            var now = DateTime.UtcNow;
            var fromStatus = specialist.Status;
            specialist.SubmittedAt = now;
            specialist.RejectionReason = null;
            specialist.ReviewedAt = null;
            specialist.ReviewedByUserId = null;
            await ApplyStatusTransitionAsync(specialist, fromStatus, SpecialistStatus.Pending, userId, null, now);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<StatusChangeResponse>.SuccessResponse(
                MapStatusChange(specialist),
                "تم ارسال البيانات بنجاح!");
        }
        catch (Exception ex)
        {
            return ApiResponse<StatusChangeResponse>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<StatusChangeResponse>> CancelApplicationAsync(Guid applicationId, Guid userId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetByIdAsync(applicationId);
            var ownership = ValidateOwnership<StatusChangeResponse>(specialist, userId);
            if (ownership != null)
            {
                return ownership;
            }

            if (specialist!.Status != SpecialistStatus.Pending && specialist.Status != SpecialistStatus.Draft)
            {
                return ApiResponse<StatusChangeResponse>.FailureResponse(
                    "لا يمكن إلغاء الطلب في هذه الحالة");
            }

            await ApplyStatusTransitionAsync(specialist, specialist.Status, SpecialistStatus.Cancelled, userId);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<StatusChangeResponse>.SuccessResponse(
                MapStatusChange(specialist),
                "تم إلغاء طلب التقدم بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<StatusChangeResponse>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<StatusChangeResponse>> StartEditApplicationAsync(Guid applicationId, Guid userId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetByIdAsync(applicationId);
            var ownership = ValidateOwnership<StatusChangeResponse>(specialist, userId);
            if (ownership != null)
            {
                return ownership;
            }

            if (specialist!.Status != SpecialistStatus.Pending)
            {
                return ApiResponse<StatusChangeResponse>.FailureResponse(
                    "لا يمكن تعديل الطلب - الطلب ليس قيد المراجعة");
            }

            await ApplyStatusTransitionAsync(specialist, specialist.Status, SpecialistStatus.Draft, userId);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<StatusChangeResponse>.SuccessResponse(
                MapStatusChange(specialist),
                "يمكنك الآن تعديل البيانات وإعادة تقديم الطلب");
        }
        catch (Exception ex)
        {
            return ApiResponse<StatusChangeResponse>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<IdentityDataDto>> UpdateIdentityDataAsync(Guid applicationId, Guid userId, UpdateIdentityDataRequest request)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetByIdAsync(applicationId);
            var ready = ValidateDraftForUpdate<IdentityDataDto>(specialist, userId);
            if (ready != null)
            {
                return ready;
            }

            if (request.NationalIdFront == null && request.NationalIdBack == null && request.PersonalPhoto == null)
            {
                return ApiResponse<IdentityDataDto>.FailureResponse(
                    "خطأ في البيانات المدخلة",
                    new List<string> { "يجب إرفاق ملف واحد على الأقل" });
            }

            if (request.NationalIdFront != null)
            {
                specialist!.IdFrontImageUrl = await ReplaceDocumentAsync(specialist, specialist.IdFrontImageUrl, request.NationalIdFront, "id-front");
            }

            if (request.NationalIdBack != null)
            {
                specialist!.IdBackImageUrl = await ReplaceDocumentAsync(specialist, specialist.IdBackImageUrl, request.NationalIdBack, "id-back");
            }

            if (request.PersonalPhoto != null)
            {
                specialist!.PersonalPhotoUrl = await ReplaceDocumentAsync(specialist, specialist.PersonalPhotoUrl, request.PersonalPhoto, "personal-photo");
            }

            specialist!.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Specialists.UpdateAsync(specialist);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<IdentityDataDto>.SuccessResponse(
                MapIdentityData(specialist),
                "تم تحديث بيانات الهوية بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<IdentityDataDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<ProfessionalDataDto>> UpdateProfessionalDataAsync(Guid applicationId, Guid userId, UpdateProfessionalDataRequest request)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetByIdAsync(applicationId);
            var ready = ValidateDraftForUpdate<ProfessionalDataDto>(specialist, userId);
            if (ready != null)
            {
                return ready;
            }

            if (request.SpecialtyId == null
                && string.IsNullOrWhiteSpace(request.PracticeLicenseNumber)
                && request.SpecializationCertificate == null
                && request.ProfessionalLicense == null
                && request.SyndicateCard == null)
            {
                return ApiResponse<ProfessionalDataDto>.FailureResponse(
                    "خطأ في البيانات المدخلة",
                    new List<string> { "يجب إدخال بيانات أو إرفاق ملف واحد على الأقل" });
            }

            if (request.SpecialtyId.HasValue)
            {
                var specialty = await _unitOfWork.Specialties.GetByIdAsync(request.SpecialtyId.Value);
                if (specialty == null || !specialty.IsActive)
                {
                    return ApiResponse<ProfessionalDataDto>.FailureResponse(
                        "خطأ في البيانات المدخلة",
                        new List<string> { "التخصص المختار غير صحيح" });
                }

                specialist!.Specialization = specialty.NameAr;
            }

            if (!string.IsNullOrWhiteSpace(request.PracticeLicenseNumber)
                && request.PracticeLicenseNumber.Trim() != specialist!.PracticeLicenseNumber)
            {
                var newLicenseNumber = request.PracticeLicenseNumber.Trim();
                var exists = await _unitOfWork.Specialists.ExistsAsync(s =>
                    s.Id != specialist.Id && s.PracticeLicenseNumber == newLicenseNumber);

                if (exists)
                {
                    return ApiResponse<ProfessionalDataDto>.FailureResponse(
                        "رقم الترخيص المهني مسجل بالفعل",
                        new List<string> { "رقم الترخيص المهني مسجل بالفعل" });
                }

                specialist.PracticeLicenseNumber = newLicenseNumber;
            }

            if (request.SpecializationCertificate != null)
            {
                specialist!.SpecializationCertificateImageUrl = await ReplaceDocumentAsync(specialist, specialist.SpecializationCertificateImageUrl, request.SpecializationCertificate, "specialization-certificate");
            }

            if (request.ProfessionalLicense != null)
            {
                specialist!.PracticeLicenseImageUrl = await ReplaceDocumentAsync(specialist, specialist.PracticeLicenseImageUrl, request.ProfessionalLicense, "practice-license");
            }

            if (request.SyndicateCard != null)
            {
                specialist!.UnionCardImageUrl = await ReplaceDocumentAsync(specialist, specialist.UnionCardImageUrl, request.SyndicateCard, "union-card");
            }

            specialist!.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Specialists.UpdateAsync(specialist);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<ProfessionalDataDto>.SuccessResponse(
                await MapProfessionalDataAsync(specialist),
                "تم تحديث بيانات مزاولة المهنة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ProfessionalDataDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<DocumentInfoDto>> UploadDocumentAsync(Guid applicationId, Guid userId, SpecialistDocumentType documentType, IFormFile file)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetByIdAsync(applicationId);
            var ready = ValidateDraftForUpdate<DocumentInfoDto>(specialist, userId);
            if (ready != null)
            {
                return ready;
            }

            if (file == null || file.Length == 0)
            {
                return ApiResponse<DocumentInfoDto>.FailureResponse(
                    "خطأ في البيانات المدخلة",
                    new List<string> { "الملف مطلوب" });
            }

            var (_, subfolder) = MapDocumentType(documentType);
            var oldUrl = GetDocumentUrl(specialist!, documentType);
            var newUrl = await ReplaceDocumentAsync(specialist!, oldUrl, file, subfolder);
            SetDocumentUrl(specialist!, documentType, newUrl);

            specialist!.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Specialists.UpdateAsync(specialist);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<DocumentInfoDto>.SuccessResponse(
                MapDocumentInfo(documentType, newUrl),
                "تم تحديث المستند بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<DocumentInfoDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<DocumentInfoDto>> GetDocumentAsync(Guid applicationId, Guid userId, SpecialistDocumentType documentType)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetByIdAsync(applicationId);
            var ownership = ValidateOwnership<DocumentInfoDto>(specialist, userId);
            if (ownership != null)
            {
                return ownership;
            }

            var url = GetDocumentUrl(specialist!, documentType);
            if (string.IsNullOrWhiteSpace(url))
            {
                return ApiResponse<DocumentInfoDto>.FailureResponse(
                    "لم يتم العثور على المستند",
                    new List<string> { "لم يتم رفع المستند بعد" });
            }

            return ApiResponse<DocumentInfoDto>.SuccessResponse(
                MapDocumentInfo(documentType, url),
                "تم جلب المستند بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<DocumentInfoDto>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<StatusChangeResponse>> CreateNewApplicationAsync(Guid userId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.UserId == userId);
            if (specialist == null)
            {
                return ApiResponse<StatusChangeResponse>.FailureResponse(
                    "لم يتم العثور على الطلب",
                    new List<string> { "لم يتم العثور على بيانات الأخصائي لهذا المستخدم" });
            }

            if (!CanCreateNew(specialist.Status))
            {
                return ApiResponse<StatusChangeResponse>.FailureResponse(
                    "لا يمكن إنشاء طلب جديد في هذه الحالة");
            }

            var fromStatus = specialist.Status;
            specialist.RejectionReason = null;
            specialist.ReviewedAt = null;
            specialist.ReviewedByUserId = null;
            specialist.SubmittedAt = null;
            await ApplyStatusTransitionAsync(specialist, fromStatus, SpecialistStatus.Draft, userId);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<StatusChangeResponse>.SuccessResponse(
                MapStatusChange(specialist),
                "تم إنشاء طلب تقدم جديد، يمكنك تعديل البيانات وإرسال الطلب");
        }
        catch (Exception ex)
        {
            return ApiResponse<StatusChangeResponse>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<IEnumerable<SpecialtyDto>>> GetSpecialtiesAsync()
    {
        try
        {
            var specialties = (await _unitOfWork.Specialties.FindAsync(s => s.IsActive))
                .OrderBy(s => s.Id)
                .Select(s => new SpecialtyDto
                {
                    Id = s.Id,
                    NameAr = s.NameAr,
                    NameEn = s.NameEn
                })
                .ToList();

            return ApiResponse<IEnumerable<SpecialtyDto>>.SuccessResponse(
                specialties,
                "تم جلب التخصصات بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<IEnumerable<SpecialtyDto>>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<AdminApplicationListResponse>> GetApplicationsForAdminAsync(int? status, int page, int pageSize)
    {
        try
        {
            var normalizedPage = Math.Max(page, 1);
            var normalizedPageSize = Math.Clamp(pageSize, 1, 100);
            var specialists = await _unitOfWork.Specialists.GetAllAsync();
            var query = specialists.AsEnumerable();

            if (status.HasValue)
            {
                if (!Enum.IsDefined(typeof(SpecialistStatus), status.Value))
                {
                    return ApiResponse<AdminApplicationListResponse>.FailureResponse(
                        "حالة غير صحيحة",
                        new List<string> { "الحالة المحددة غير صحيحة" });
                }

                var specialistStatus = (SpecialistStatus)status.Value;
                query = query.Where(s => s.Status == specialistStatus);
            }

            var ordered = query.OrderByDescending(s => s.SubmittedAt ?? s.CreatedAt).ToList();
            var totalCount = ordered.Count;
            var pageItems = ordered
                .Skip((normalizedPage - 1) * normalizedPageSize)
                .Take(normalizedPageSize)
                .ToList();

            var items = new List<AdminApplicationListItemDto>();
            foreach (var specialist in pageItems)
            {
                var user = await _unitOfWork.Users.GetByIdAsync(specialist.UserId);
                items.Add(new AdminApplicationListItemDto
                {
                    ApplicationId = specialist.Id,
                    SpecialistName = user?.FullName ?? string.Empty,
                    SpecialtyName = specialist.Specialization,
                    SubmittedAt = specialist.SubmittedAt,
                    Status = GetStatusKey(specialist.Status),
                    StatusAr = GetStatusArabicLabel(specialist.Status),
                    PersonalPhotoUrl = specialist.PersonalPhotoUrl
                });
            }

            return ApiResponse<AdminApplicationListResponse>.SuccessResponse(
                new AdminApplicationListResponse
                {
                    Items = items,
                    TotalCount = totalCount,
                    Page = normalizedPage,
                    PageSize = normalizedPageSize
                },
                "تم جلب طلبات التقدم بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<AdminApplicationListResponse>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<AdminApplicationDetailResponse>> GetApplicationForAdminAsync(Guid applicationId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetByIdAsync(applicationId);
            if (specialist == null)
            {
                return ApiResponse<AdminApplicationDetailResponse>.FailureResponse(
                    "لم يتم العثور على الطلب",
                    new List<string> { "لم يتم العثور على الطلب" });
            }

            var user = await _unitOfWork.Users.GetByIdAsync(specialist.UserId);
            if (user == null)
            {
                return ApiResponse<AdminApplicationDetailResponse>.FailureResponse(
                    "خطأ في البيانات",
                    new List<string> { "لم يتم العثور على بيانات المستخدم المرتبط" });
            }

            var details = await MapApplicationDetailsAsync(specialist);
            var histories = (await _unitOfWork.SpecialistStatusHistories.FindAsync(h => h.SpecialistId == specialist.Id))
                .OrderByDescending(h => h.ChangedAt)
                .Select(h => new StatusHistoryDto
                {
                    FromStatus = GetStatusKey(h.FromStatus),
                    ToStatus = GetStatusKey(h.ToStatus),
                    ChangedAt = h.ChangedAt,
                    Reason = h.Reason,
                    ChangedByUserId = h.ChangedByUserId
                })
                .ToList();

            return ApiResponse<AdminApplicationDetailResponse>.SuccessResponse(
                new AdminApplicationDetailResponse
                {
                    ApplicationId = details.ApplicationId,
                    Status = details.Status,
                    StatusAr = details.StatusAr,
                    SubmittedAt = details.SubmittedAt,
                    RejectionReason = details.RejectionReason,
                    IdentityData = details.IdentityData,
                    ProfessionalData = details.ProfessionalData,
                    CanEdit = details.CanEdit,
                    CanCancel = details.CanCancel,
                    SpecialistName = user.FullName,
                    Email = user.Email,
                    Phone = specialist.Phone,
                    StatusHistory = histories
                },
                "تم جلب تفاصيل الطلب بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<AdminApplicationDetailResponse>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<StatusChangeResponse>> ApproveApplicationAsync(Guid applicationId, Guid adminUserId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetByIdAsync(applicationId);
            if (specialist == null)
            {
                return ApiResponse<StatusChangeResponse>.FailureResponse(
                    "لم يتم العثور على الطلب",
                    new List<string> { "لم يتم العثور على الطلب" });
            }

            if (specialist.Status != SpecialistStatus.Pending)
            {
                return ApiResponse<StatusChangeResponse>.FailureResponse(
                    "لا يمكن قبول الطلب - الطلب ليس قيد المراجعة");
            }

            var now = DateTime.UtcNow;
            specialist.ReviewedAt = now;
            specialist.ReviewedByUserId = adminUserId;
            specialist.RejectionReason = null;
            await ApplyStatusTransitionAsync(specialist, specialist.Status, SpecialistStatus.Approved, adminUserId, null, now);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<StatusChangeResponse>.SuccessResponse(
                MapStatusChange(specialist),
                "تم قبول طلب الأخصائي بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<StatusChangeResponse>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<StatusChangeResponse>> RejectApplicationAsync(Guid applicationId, Guid adminUserId, RejectApplicationRequest request)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.RejectionReason))
            {
                return ApiResponse<StatusChangeResponse>.FailureResponse(
                    "سبب الرفض مطلوب",
                    new List<string> { "سبب الرفض مطلوب" });
            }

            var specialist = await _unitOfWork.Specialists.GetByIdAsync(applicationId);
            if (specialist == null)
            {
                return ApiResponse<StatusChangeResponse>.FailureResponse(
                    "لم يتم العثور على الطلب",
                    new List<string> { "لم يتم العثور على الطلب" });
            }

            if (specialist.Status != SpecialistStatus.Pending)
            {
                return ApiResponse<StatusChangeResponse>.FailureResponse(
                    "لا يمكن رفض الطلب - الطلب ليس قيد المراجعة");
            }

            var now = DateTime.UtcNow;
            var reason = request.RejectionReason.Trim();
            specialist.ReviewedAt = now;
            specialist.ReviewedByUserId = adminUserId;
            specialist.RejectionReason = reason;
            await ApplyStatusTransitionAsync(specialist, specialist.Status, SpecialistStatus.Rejected, adminUserId, reason, now);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<StatusChangeResponse>.SuccessResponse(
                MapStatusChange(specialist),
                "تم رفض طلب الأخصائي");
        }
        catch (Exception ex)
        {
            return ApiResponse<StatusChangeResponse>.FailureResponse(
                "حدث خطأ في الخادم",
                new List<string> { ex.Message });
        }
    }

    private static ApiResponse<T>? ValidateOwnership<T>(Specialist? specialist, Guid userId)
    {
        if (specialist == null)
        {
            return ApiResponse<T>.FailureResponse(
                "لم يتم العثور على الطلب",
                new List<string> { "لم يتم العثور على الطلب" });
        }

        if (specialist.UserId != userId)
        {
            return ApiResponse<T>.FailureResponse(
                "غير مصرح - هذا الطلب لا يخصك",
                new List<string> { "غير مصرح - هذا الطلب لا يخصك" });
        }

        return null;
    }

    private static ApiResponse<T>? ValidateDraftForUpdate<T>(Specialist? specialist, Guid userId)
    {
        var ownership = ValidateOwnership<T>(specialist, userId);
        if (ownership != null)
        {
            return ownership;
        }

        if (specialist!.Status != SpecialistStatus.Draft)
        {
            return ApiResponse<T>.FailureResponse(
                "لا يمكن تعديل البيانات - الطلب ليس في حالة مسودة");
        }

        return null;
    }

    private async Task ApplyStatusTransitionAsync(
        Specialist specialist,
        SpecialistStatus fromStatus,
        SpecialistStatus toStatus,
        Guid changedByUserId,
        string? reason = null,
        DateTime? changedAt = null)
    {
        var now = changedAt ?? DateTime.UtcNow;
        await _unitOfWork.SpecialistStatusHistories.AddAsync(new SpecialistStatusHistory
        {
            Id = Guid.NewGuid(),
            SpecialistId = specialist.Id,
            FromStatus = fromStatus,
            ToStatus = toStatus,
            Reason = reason,
            ChangedByUserId = changedByUserId,
            ChangedAt = now
        });

        specialist.Status = toStatus;
        specialist.UpdatedAt = now;
        await _unitOfWork.Specialists.UpdateAsync(specialist);
    }

    private async Task<string> ReplaceDocumentAsync(Specialist specialist, string? oldUrl, IFormFile file, string subfolder)
    {
        var newUrl = await _imageService.UploadSpecialistImageAsync(file, specialist.Id, subfolder);
        if (!string.IsNullOrWhiteSpace(oldUrl))
        {
            await _imageService.DeleteBlobByUrlAsync(oldUrl);
        }

        return newUrl;
    }

    private async Task<ApplicationDetailsResponse> MapApplicationDetailsAsync(Specialist specialist)
    {
        return new ApplicationDetailsResponse
        {
            ApplicationId = specialist.Id,
            Status = GetStatusKey(specialist.Status),
            StatusAr = GetStatusArabicLabel(specialist.Status),
            SubmittedAt = specialist.SubmittedAt,
            RejectionReason = specialist.RejectionReason,
            IdentityData = MapIdentityData(specialist),
            ProfessionalData = await MapProfessionalDataAsync(specialist),
            CanEdit = CanEdit(specialist.Status),
            CanCancel = CanCancel(specialist.Status)
        };
    }

    private static IdentityDataDto MapIdentityData(Specialist specialist)
    {
        return new IdentityDataDto
        {
            NationalIdFrontUrl = specialist.IdFrontImageUrl,
            NationalIdFrontUploaded = !string.IsNullOrWhiteSpace(specialist.IdFrontImageUrl),
            NationalIdBackUrl = specialist.IdBackImageUrl,
            NationalIdBackUploaded = !string.IsNullOrWhiteSpace(specialist.IdBackImageUrl),
            PersonalPhotoUrl = specialist.PersonalPhotoUrl,
            PersonalPhotoUploaded = !string.IsNullOrWhiteSpace(specialist.PersonalPhotoUrl)
        };
    }

    private async Task<ProfessionalDataDto> MapProfessionalDataAsync(Specialist specialist)
    {
        var specialty = await FindSpecialtyByNameAsync(specialist.Specialization);
        return new ProfessionalDataDto
        {
            SpecialtyName = specialist.Specialization,
            SpecialtyId = specialty?.Id,
            SpecializationCertificateUrl = specialist.SpecializationCertificateImageUrl,
            SpecializationCertificateUploaded = !string.IsNullOrWhiteSpace(specialist.SpecializationCertificateImageUrl),
            PracticeLicenseNumber = specialist.PracticeLicenseNumber,
            ProfessionalLicenseUrl = specialist.PracticeLicenseImageUrl,
            ProfessionalLicenseUploaded = !string.IsNullOrWhiteSpace(specialist.PracticeLicenseImageUrl),
            SyndicateCardUrl = specialist.UnionCardImageUrl,
            SyndicateCardUploaded = !string.IsNullOrWhiteSpace(specialist.UnionCardImageUrl)
        };
    }

    private async Task<Specialty?> FindSpecialtyByNameAsync(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            return null;
        }

        var normalized = name.Trim();
        return await _unitOfWork.Specialties.GetFirstOrDefaultAsync(s =>
            s.NameAr == normalized || s.NameEn == normalized);
    }

    private static StatusChangeResponse MapStatusChange(Specialist specialist)
    {
        return new StatusChangeResponse
        {
            ApplicationId = specialist.Id,
            Status = GetStatusKey(specialist.Status),
            StatusAr = GetStatusArabicLabel(specialist.Status),
            SubmittedAt = specialist.SubmittedAt,
            ReviewedAt = specialist.ReviewedAt,
            RejectionReason = specialist.RejectionReason
        };
    }

    private static DocumentInfoDto MapDocumentInfo(SpecialistDocumentType type, string? url)
    {
        return new DocumentInfoDto
        {
            DocumentType = type.ToString(),
            DocumentUrl = url,
            Uploaded = !string.IsNullOrWhiteSpace(url)
        };
    }

    private static List<string> GetSubmitValidationErrors(Specialist specialist)
    {
        var errors = new List<string>();
        if (string.IsNullOrWhiteSpace(specialist.IdFrontImageUrl))
        {
            errors.Add("صورة بطاقة الوجه الامامي مطلوبة");
        }

        if (string.IsNullOrWhiteSpace(specialist.PersonalPhotoUrl))
        {
            errors.Add("الصورة الشخصية مطلوبة");
        }

        if (string.IsNullOrWhiteSpace(specialist.SpecializationCertificateImageUrl))
        {
            errors.Add("صورة شهادة التخصص مطلوبة");
        }

        if (string.IsNullOrWhiteSpace(specialist.PracticeLicenseImageUrl))
        {
            errors.Add("صورة الترخيص المهني مطلوبة");
        }

        if (string.IsNullOrWhiteSpace(specialist.UnionCardImageUrl))
        {
            errors.Add("صورة كارنيه النقابة مطلوبة");
        }

        if (string.IsNullOrWhiteSpace(specialist.Specialization))
        {
            errors.Add("التخصص مطلوب");
        }

        if (string.IsNullOrWhiteSpace(specialist.PracticeLicenseNumber))
        {
            errors.Add("رقم الترخيص المهني مطلوب");
        }

        return errors;
    }

    private static (string FieldName, string Subfolder) MapDocumentType(SpecialistDocumentType type) => type switch
    {
        SpecialistDocumentType.NationalIdFront => (nameof(Specialist.IdFrontImageUrl), "id-front"),
        SpecialistDocumentType.NationalIdBack => (nameof(Specialist.IdBackImageUrl), "id-back"),
        SpecialistDocumentType.PersonalPhoto => (nameof(Specialist.PersonalPhotoUrl), "personal-photo"),
        SpecialistDocumentType.SpecializationCertificate => (nameof(Specialist.SpecializationCertificateImageUrl), "specialization-certificate"),
        SpecialistDocumentType.ProfessionalLicense => (nameof(Specialist.PracticeLicenseImageUrl), "practice-license"),
        SpecialistDocumentType.SyndicateCard => (nameof(Specialist.UnionCardImageUrl), "union-card"),
        _ => throw new ArgumentOutOfRangeException(nameof(type))
    };

    private static string? GetDocumentUrl(Specialist specialist, SpecialistDocumentType type) => type switch
    {
        SpecialistDocumentType.NationalIdFront => specialist.IdFrontImageUrl,
        SpecialistDocumentType.NationalIdBack => specialist.IdBackImageUrl,
        SpecialistDocumentType.PersonalPhoto => specialist.PersonalPhotoUrl,
        SpecialistDocumentType.SpecializationCertificate => specialist.SpecializationCertificateImageUrl,
        SpecialistDocumentType.ProfessionalLicense => specialist.PracticeLicenseImageUrl,
        SpecialistDocumentType.SyndicateCard => specialist.UnionCardImageUrl,
        _ => null
    };

    private static void SetDocumentUrl(Specialist specialist, SpecialistDocumentType type, string url)
    {
        switch (type)
        {
            case SpecialistDocumentType.NationalIdFront:
                specialist.IdFrontImageUrl = url;
                break;
            case SpecialistDocumentType.NationalIdBack:
                specialist.IdBackImageUrl = url;
                break;
            case SpecialistDocumentType.PersonalPhoto:
                specialist.PersonalPhotoUrl = url;
                break;
            case SpecialistDocumentType.SpecializationCertificate:
                specialist.SpecializationCertificateImageUrl = url;
                break;
            case SpecialistDocumentType.ProfessionalLicense:
                specialist.PracticeLicenseImageUrl = url;
                break;
            case SpecialistDocumentType.SyndicateCard:
                specialist.UnionCardImageUrl = url;
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(type));
        }
    }

    private static bool CanEdit(SpecialistStatus status)
    {
        return status == SpecialistStatus.Pending || status == SpecialistStatus.Rejected;
    }

    private static bool CanCancel(SpecialistStatus status)
    {
        return status == SpecialistStatus.Pending || status == SpecialistStatus.Draft;
    }

    private static bool CanCreateNew(SpecialistStatus status)
    {
        return status == SpecialistStatus.Cancelled || status == SpecialistStatus.Rejected;
    }

    public static string GetStatusKey(SpecialistStatus status) => status switch
    {
        SpecialistStatus.Pending => "PendingReview",
        _ => status.ToString()
    };

    public static string GetStatusArabicLabel(SpecialistStatus status) => status switch
    {
        SpecialistStatus.Draft => "مسودة",
        SpecialistStatus.Pending => "جاري المراجعة",
        SpecialistStatus.Approved => "تم القبول",
        SpecialistStatus.Rejected => "لم يتم القبول",
        SpecialistStatus.Cancelled => "تم الغاء الطلب",
        _ => "غير معروف"
    };
}
