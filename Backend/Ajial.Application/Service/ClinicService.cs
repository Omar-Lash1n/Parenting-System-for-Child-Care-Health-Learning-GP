using System.Text.Json;
using Ajial.Application.DTOs.Clinic;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;
using Microsoft.AspNetCore.Http;

namespace Ajial.Application.Service;

public class ClinicService : IClinicService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IImageService _imageService;

    public ClinicService(IUnitOfWork unitOfWork, IImageService imageService)
    {
        _unitOfWork = unitOfWork;
        _imageService = imageService;
    }

    // ── Doctor endpoints ──────────────────────────────────────────────────────

    public async Task<ApiResponse<List<ClinicCardResponse>>> GetDoctorClinicsAsync(Guid userId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.UserId == userId);
            if (specialist == null)
                return ApiResponse<List<ClinicCardResponse>>.FailureResponse("لم يتم العثور على بيانات الطبيب");

            var clinics = (await _unitOfWork.Clinics.FindAsync(c => c.SpecialistId == specialist.Id))
                .OrderByDescending(c => c.SubmittedAt ?? c.CreatedAt)
                .Select(MapToCard)
                .ToList();

            return ApiResponse<List<ClinicCardResponse>>.SuccessResponse(clinics, "تم جلب العيادات بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<List<ClinicCardResponse>>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<ClinicDetailResponse>> GetClinicDetailAsync(Guid clinicId, Guid userId)
    {
        try
        {
            var (clinic, error) = await ResolveClinicForDoctor<ClinicDetailResponse>(clinicId, userId);
            if (error != null) return error;

            var governorateName = clinic!.GovernorateId.HasValue
                ? (await _unitOfWork.Cities.GetByIdAsync(clinic.GovernorateId.Value))?.NameAr
                : null;

            return ApiResponse<ClinicDetailResponse>.SuccessResponse(
                MapToDetail(clinic!, governorateName), "تم جلب تفاصيل العيادة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ClinicDetailResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<ClinicStatusChangeResponse>> CreateClinicAsync(Guid userId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.UserId == userId);
            if (specialist == null)
                return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("لم يتم العثور على بيانات الطبيب");

            if (specialist.Status != SpecialistStatus.Approved)
                return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("لا يمكن إضافة عيادة قبل قبول طلب التسجيل");

            var clinic = new Clinic
            {
                Id = Guid.NewGuid(),
                SpecialistId = specialist.Id,
                Status = ClinicStatus.Draft,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.Clinics.AddAsync(clinic);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<ClinicStatusChangeResponse>.SuccessResponse(
                MapToStatusChange(clinic), "تم إنشاء مسودة العيادة، يمكنك إضافة البيانات الآن");
        }
        catch (Exception ex)
        {
            return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<ClinicDetailResponse>> UpdateClinicDetailsAsync(Guid clinicId, Guid userId, UpdateClinicDetailsRequest request)
    {
        try
        {
            var (clinic, error) = await ResolveClinicForDoctor<ClinicDetailResponse>(clinicId, userId);
            if (error != null) return error;

            if (!IsDraftOrRejected(clinic!.Status))
                return ApiResponse<ClinicDetailResponse>.FailureResponse("لا يمكن تعديل البيانات في الحالة الحالية");

            if (request.Name != null) clinic!.Name = request.Name.Trim();
            if (request.GovernorateId.HasValue) clinic!.GovernorateId = request.GovernorateId.Value;
            if (request.DistrictName != null) clinic!.DistrictName = request.DistrictName.Trim();
            if (request.Address != null) clinic!.Address = request.Address.Trim();
            if (request.Phone != null) clinic!.Phone = request.Phone.Trim();

            clinic!.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Clinics.UpdateAsync(clinic);
            await _unitOfWork.SaveChangesAsync();

            string? governorateName = clinic.GovernorateId.HasValue
                ? (await _unitOfWork.Cities.GetByIdAsync(clinic.GovernorateId.Value))?.NameAr
                : null;

            return ApiResponse<ClinicDetailResponse>.SuccessResponse(
                MapToDetail(clinic, governorateName), "تم تحديث تفاصيل العيادة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ClinicDetailResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<ClinicDetailResponse>> UpdateClinicHoursAsync(Guid clinicId, Guid userId, UpdateClinicHoursRequest request)
    {
        try
        {
            var (clinic, error) = await ResolveClinicForDoctor<ClinicDetailResponse>(clinicId, userId);
            if (error != null) return error;

            if (!IsDraftOrRejected(clinic!.Status))
                return ApiResponse<ClinicDetailResponse>.FailureResponse("لا يمكن تعديل البيانات في الحالة الحالية");

            if (request.WorkingHoursJson != null)
            {
                if (!IsValidJson(request.WorkingHoursJson))
                    return ApiResponse<ClinicDetailResponse>.FailureResponse(
                        "خطأ في البيانات المدخلة", new List<string> { "صيغة مواعيد العمل غير صحيحة" });
                clinic!.WorkingHoursJson = request.WorkingHoursJson;
            }

            if (request.ExaminationPrice.HasValue) clinic!.ExaminationPrice = request.ExaminationPrice.Value;
            if (request.ConsultationPrice.HasValue) clinic!.ConsultationPrice = request.ConsultationPrice.Value;

            clinic!.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Clinics.UpdateAsync(clinic);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<ClinicDetailResponse>.SuccessResponse(
                MapToDetail(clinic, null), "تم تحديث مواعيد العمل والتكلفة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ClinicDetailResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<ClinicDocumentInfoResponse>> UploadClinicDocumentAsync(Guid clinicId, Guid userId, ClinicDocumentType documentType, IFormFile file)
    {
        try
        {
            var (clinic, error) = await ResolveClinicForDoctor<ClinicDocumentInfoResponse>(clinicId, userId);
            if (error != null) return error;

            if (!IsDraftOrRejected(clinic!.Status))
                return ApiResponse<ClinicDocumentInfoResponse>.FailureResponse("لا يمكن تعديل البيانات في الحالة الحالية");

            if (file == null || file.Length == 0)
                return ApiResponse<ClinicDocumentInfoResponse>.FailureResponse(
                    "خطأ في البيانات المدخلة", new List<string> { "الملف مطلوب" });

            var subfolder = GetDocumentSubfolder(documentType);
            var oldUrl = GetDocumentUrl(clinic, documentType);

            if (!string.IsNullOrWhiteSpace(oldUrl))
                await _imageService.DeleteBlobByUrlAsync(oldUrl);

            var newUrl = await _imageService.UploadClinicImageAsync(file, clinic.Id, subfolder);
            SetDocumentUrl(clinic, documentType, newUrl);

            clinic.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Clinics.UpdateAsync(clinic);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<ClinicDocumentInfoResponse>.SuccessResponse(
                new ClinicDocumentInfoResponse { DocumentType = documentType.ToString(), Url = newUrl },
                "تم رفع المستند بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ClinicDocumentInfoResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<ClinicStatusChangeResponse>> SubmitClinicAsync(Guid clinicId, Guid userId)
    {
        try
        {
            var (clinic, error) = await ResolveClinicForDoctor<ClinicStatusChangeResponse>(clinicId, userId);
            if (error != null) return error;

            if (!IsDraftOrRejected(clinic!.Status))
                return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("لا يمكن تقديم الطلب في الحالة الحالية");

            var missing = GetSubmitValidationErrors(clinic);
            if (missing.Count > 0)
                return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("يوجد بيانات مطلوبة غير مكتملة", missing);

            clinic.Status = ClinicStatus.Pending;
            clinic.SubmittedAt = DateTime.UtcNow;
            clinic.RejectionReason = null;
            clinic.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Clinics.UpdateAsync(clinic);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<ClinicStatusChangeResponse>.SuccessResponse(
                MapToStatusChange(clinic), "تم ارسال بيانات العيادة بنجاح!");
        }
        catch (Exception ex)
        {
            return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<ClinicStatusChangeResponse>> CancelClinicAsync(Guid clinicId, Guid userId)
    {
        try
        {
            var (clinic, error) = await ResolveClinicForDoctor<ClinicStatusChangeResponse>(clinicId, userId);
            if (error != null) return error;

            if (clinic!.Status != ClinicStatus.Draft && clinic.Status != ClinicStatus.Pending && clinic.Status != ClinicStatus.Rejected)
                return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("لا يمكن إلغاء الطلب في الحالة الحالية");

            clinic.Status = ClinicStatus.Cancelled;
            clinic.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Clinics.UpdateAsync(clinic);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<ClinicStatusChangeResponse>.SuccessResponse(
                MapToStatusChange(clinic), "تم إلغاء طلب إضافة العيادة");
        }
        catch (Exception ex)
        {
            return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<ClinicStatusChangeResponse>> StartEditClinicAsync(Guid clinicId, Guid userId)
    {
        try
        {
            var (clinic, error) = await ResolveClinicForDoctor<ClinicStatusChangeResponse>(clinicId, userId);
            if (error != null) return error;

            if (clinic!.Status != ClinicStatus.Pending)
                return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("لا يمكن تعديل الطلب - الطلب ليس قيد المراجعة");

            clinic.Status = ClinicStatus.Draft;
            clinic.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Clinics.UpdateAsync(clinic);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<ClinicStatusChangeResponse>.SuccessResponse(
                MapToStatusChange(clinic), "يمكنك الآن تعديل البيانات وإعادة تقديم الطلب");
        }
        catch (Exception ex)
        {
            return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── Admin endpoints ───────────────────────────────────────────────────────

    public async Task<ApiResponse<AdminClinicListResponse>> GetClinicsForAdminAsync(int? status, int page, int pageSize)
    {
        try
        {
            var normalizedPage = Math.Max(page, 1);
            var normalizedSize = Math.Clamp(pageSize, 1, 100);

            var all = await _unitOfWork.Clinics.GetAllAsync();
            var query = all.AsEnumerable();

            if (status.HasValue)
            {
                if (!Enum.IsDefined(typeof(ClinicStatus), status.Value))
                    return ApiResponse<AdminClinicListResponse>.FailureResponse("حالة غير صحيحة");

                query = query.Where(c => (int)c.Status == status.Value);
            }

            var ordered = query.OrderByDescending(c => c.SubmittedAt ?? c.CreatedAt).ToList();
            var total = ordered.Count;
            var page_items = ordered.Skip((normalizedPage - 1) * normalizedSize).Take(normalizedSize).ToList();

            var items = new List<AdminClinicListItemDto>();
            foreach (var clinic in page_items)
            {
                var specialist = await _unitOfWork.Specialists.GetByIdAsync(clinic.SpecialistId);
                var user = specialist != null ? await _unitOfWork.Users.GetByIdAsync(specialist.UserId) : null;
                items.Add(new AdminClinicListItemDto
                {
                    ClinicId = clinic.Id,
                    ClinicName = clinic.Name,
                    DoctorName = user?.FullName ?? string.Empty,
                    Status = GetStatusKey(clinic.Status),
                    StatusAr = GetStatusArabicLabel(clinic.Status),
                    SubmittedAt = clinic.SubmittedAt
                });
            }

            return ApiResponse<AdminClinicListResponse>.SuccessResponse(new AdminClinicListResponse
            {
                TotalCount = total,
                Page = normalizedPage,
                PageSize = normalizedSize,
                Items = items
            }, "تم جلب قائمة العيادات بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<AdminClinicListResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<AdminClinicDetailResponse>> GetClinicForAdminAsync(Guid clinicId)
    {
        try
        {
            var clinic = await _unitOfWork.Clinics.GetByIdAsync(clinicId);
            if (clinic == null)
                return ApiResponse<AdminClinicDetailResponse>.FailureResponse("لم يتم العثور على العيادة");

            var specialist = await _unitOfWork.Specialists.GetByIdAsync(clinic.SpecialistId);
            var user = specialist != null ? await _unitOfWork.Users.GetByIdAsync(specialist.UserId) : null;
            var governorateName = clinic.GovernorateId.HasValue
                ? (await _unitOfWork.Cities.GetByIdAsync(clinic.GovernorateId.Value))?.NameAr
                : null;

            return ApiResponse<AdminClinicDetailResponse>.SuccessResponse(new AdminClinicDetailResponse
            {
                ClinicId = clinic.Id,
                SpecialistId = clinic.SpecialistId,
                DoctorName = user?.FullName ?? string.Empty,
                Status = GetStatusKey(clinic.Status),
                StatusAr = GetStatusArabicLabel(clinic.Status),
                SubmittedAt = clinic.SubmittedAt,
                RejectionReason = clinic.RejectionReason,
                Name = clinic.Name,
                GovernorateName = governorateName,
                DistrictName = clinic.DistrictName,
                Address = clinic.Address,
                Phone = clinic.Phone,
                WorkingHoursJson = clinic.WorkingHoursJson,
                ExaminationPrice = clinic.ExaminationPrice,
                ConsultationPrice = clinic.ConsultationPrice,
                LicenseImageUrl = clinic.LicenseImageUrl,
                SyndicateRegistrationImageUrl = clinic.SyndicateRegistrationImageUrl,
                HazardousWasteImageUrl = clinic.HazardousWasteImageUrl,
                ExteriorImageUrl = clinic.ExteriorImageUrl,
                InteriorImageUrl = clinic.InteriorImageUrl
            }, "تم جلب تفاصيل العيادة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<AdminClinicDetailResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<ClinicStatusChangeResponse>> ApproveClinicAsync(Guid clinicId, Guid adminUserId)
    {
        try
        {
            var clinic = await _unitOfWork.Clinics.GetByIdAsync(clinicId);
            if (clinic == null)
                return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("لم يتم العثور على العيادة");

            if (clinic.Status != ClinicStatus.Pending)
                return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("لا يمكن قبول العيادة - ليست قيد المراجعة");

            clinic.Status = ClinicStatus.Approved;
            clinic.ReviewedAt = DateTime.UtcNow;
            clinic.ReviewedByUserId = adminUserId;
            clinic.RejectionReason = null;
            clinic.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Clinics.UpdateAsync(clinic);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<ClinicStatusChangeResponse>.SuccessResponse(
                MapToStatusChange(clinic), "تم قبول العيادة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<ClinicStatusChangeResponse>> RejectClinicAsync(Guid clinicId, Guid adminUserId, RejectClinicRequest request)
    {
        try
        {
            var clinic = await _unitOfWork.Clinics.GetByIdAsync(clinicId);
            if (clinic == null)
                return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("لم يتم العثور على العيادة");

            if (clinic.Status != ClinicStatus.Pending)
                return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("لا يمكن رفض العيادة - ليست قيد المراجعة");

            clinic.Status = ClinicStatus.Rejected;
            clinic.RejectionReason = request.Reason;
            clinic.ReviewedAt = DateTime.UtcNow;
            clinic.ReviewedByUserId = adminUserId;
            clinic.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Clinics.UpdateAsync(clinic);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<ClinicStatusChangeResponse>.SuccessResponse(
                MapToStatusChange(clinic), "تم رفض العيادة");
        }
        catch (Exception ex)
        {
            return ApiResponse<ClinicStatusChangeResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private async Task<(Clinic? clinic, ApiResponse<T>? error)> ResolveClinicForDoctor<T>(Guid clinicId, Guid userId)
    {
        var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.UserId == userId);
        if (specialist == null)
            return (null, ApiResponse<T>.FailureResponse("لم يتم العثور على بيانات الطبيب"));

        var clinic = await _unitOfWork.Clinics.GetByIdAsync(clinicId);
        if (clinic == null)
            return (null, ApiResponse<T>.FailureResponse("لم يتم العثور على العيادة"));

        if (clinic.SpecialistId != specialist.Id)
            return (null, ApiResponse<T>.FailureResponse("غير مصرح - هذه العيادة لا تخصك"));

        return (clinic, null);
    }

    private static bool IsDraftOrRejected(ClinicStatus status) =>
        status == ClinicStatus.Draft || status == ClinicStatus.Rejected;

    private static List<string> GetSubmitValidationErrors(Clinic clinic)
    {
        var errors = new List<string>();
        if (string.IsNullOrWhiteSpace(clinic.Name)) errors.Add("اسم العيادة مطلوب");
        if (!clinic.GovernorateId.HasValue) errors.Add("المحافظة مطلوبة");
        if (string.IsNullOrWhiteSpace(clinic.Address)) errors.Add("العنوان مطلوب");
        if (string.IsNullOrWhiteSpace(clinic.Phone)) errors.Add("رقم موبايل العيادة مطلوب");
        if (string.IsNullOrWhiteSpace(clinic.WorkingHoursJson)) errors.Add("مواعيد العمل مطلوبة");
        if (!clinic.ExaminationPrice.HasValue) errors.Add("سعر الكشف مطلوب");
        if (!clinic.ConsultationPrice.HasValue) errors.Add("سعر الاستشارة مطلوب");
        if (string.IsNullOrWhiteSpace(clinic.LicenseImageUrl)) errors.Add("صورة ترخيص العيادة مطلوبة");
        if (string.IsNullOrWhiteSpace(clinic.SyndicateRegistrationImageUrl)) errors.Add("شهادة تسجيل العيادة بالنقابة مطلوبة");
        if (string.IsNullOrWhiteSpace(clinic.HazardousWasteImageUrl)) errors.Add("إيصال سداد رسوم النقايات الخطرة مطلوب");
        if (string.IsNullOrWhiteSpace(clinic.ExteriorImageUrl)) errors.Add("صورة العيادة من الخارج مطلوبة");
        if (string.IsNullOrWhiteSpace(clinic.InteriorImageUrl)) errors.Add("صورة العيادة من الداخل مطلوبة");
        return errors;
    }

    private static bool IsValidJson(string json)
    {
        try { JsonDocument.Parse(json); return true; }
        catch { return false; }
    }

    private static string GetDocumentSubfolder(ClinicDocumentType type) => type switch
    {
        ClinicDocumentType.LicenseImage => "clinic-license",
        ClinicDocumentType.SyndicateRegistrationImage => "clinic-syndicate",
        ClinicDocumentType.HazardousWasteImage => "clinic-hazardous-waste",
        ClinicDocumentType.ExteriorImage => "clinic-exterior",
        ClinicDocumentType.InteriorImage => "clinic-interior",
        _ => "clinic-docs"
    };

    private static string? GetDocumentUrl(Clinic clinic, ClinicDocumentType type) => type switch
    {
        ClinicDocumentType.LicenseImage => clinic.LicenseImageUrl,
        ClinicDocumentType.SyndicateRegistrationImage => clinic.SyndicateRegistrationImageUrl,
        ClinicDocumentType.HazardousWasteImage => clinic.HazardousWasteImageUrl,
        ClinicDocumentType.ExteriorImage => clinic.ExteriorImageUrl,
        ClinicDocumentType.InteriorImage => clinic.InteriorImageUrl,
        _ => null
    };

    private static void SetDocumentUrl(Clinic clinic, ClinicDocumentType type, string url)
    {
        switch (type)
        {
            case ClinicDocumentType.LicenseImage: clinic.LicenseImageUrl = url; break;
            case ClinicDocumentType.SyndicateRegistrationImage: clinic.SyndicateRegistrationImageUrl = url; break;
            case ClinicDocumentType.HazardousWasteImage: clinic.HazardousWasteImageUrl = url; break;
            case ClinicDocumentType.ExteriorImage: clinic.ExteriorImageUrl = url; break;
            case ClinicDocumentType.InteriorImage: clinic.InteriorImageUrl = url; break;
        }
    }

    private static ClinicCardResponse MapToCard(Clinic c) => new()
    {
        ClinicId = c.Id,
        Name = c.Name,
        Status = GetStatusKey(c.Status),
        StatusAr = GetStatusArabicLabel(c.Status),
        SubmittedAt = c.SubmittedAt,
        RejectionReason = c.RejectionReason,
        CanEdit = IsDraftOrRejected(c.Status),
        CanCancel = c.Status is ClinicStatus.Draft or ClinicStatus.Pending or ClinicStatus.Rejected,
        CanSubmit = IsDraftOrRejected(c.Status)
    };

    private static ClinicDetailResponse MapToDetail(Clinic c, string? governorateName) => new()
    {
        ClinicId = c.Id,
        Status = GetStatusKey(c.Status),
        StatusAr = GetStatusArabicLabel(c.Status),
        SubmittedAt = c.SubmittedAt,
        RejectionReason = c.RejectionReason,
        Name = c.Name,
        GovernorateId = c.GovernorateId,
        GovernorateName = governorateName,
        DistrictName = c.DistrictName,
        Address = c.Address,
        Phone = c.Phone,
        WorkingHoursJson = c.WorkingHoursJson,
        ExaminationPrice = c.ExaminationPrice,
        ConsultationPrice = c.ConsultationPrice,
        LicenseImageUrl = c.LicenseImageUrl,
        SyndicateRegistrationImageUrl = c.SyndicateRegistrationImageUrl,
        HazardousWasteImageUrl = c.HazardousWasteImageUrl,
        ExteriorImageUrl = c.ExteriorImageUrl,
        InteriorImageUrl = c.InteriorImageUrl,
        CanEdit = IsDraftOrRejected(c.Status),
        CanCancel = c.Status is ClinicStatus.Draft or ClinicStatus.Pending or ClinicStatus.Rejected,
        CanSubmit = IsDraftOrRejected(c.Status)
    };

    private static ClinicStatusChangeResponse MapToStatusChange(Clinic c) => new()
    {
        ClinicId = c.Id,
        Status = GetStatusKey(c.Status),
        StatusAr = GetStatusArabicLabel(c.Status)
    };

    private static string GetStatusKey(ClinicStatus s) => s switch
    {
        ClinicStatus.Draft => "draft",
        ClinicStatus.Pending => "pending",
        ClinicStatus.Approved => "approved",
        ClinicStatus.Rejected => "rejected",
        ClinicStatus.Cancelled => "cancelled",
        _ => "unknown"
    };

    private static string GetStatusArabicLabel(ClinicStatus s) => s switch
    {
        ClinicStatus.Draft => "مسودة",
        ClinicStatus.Pending => "جاري المراجعة",
        ClinicStatus.Approved => "تمت الموافقة",
        ClinicStatus.Rejected => "لم يتم القبول",
        ClinicStatus.Cancelled => "ملغي",
        _ => "غير معروف"
    };
}
