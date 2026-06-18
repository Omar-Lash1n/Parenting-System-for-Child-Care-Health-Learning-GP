using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Consultation;
using Ajial.Application.Helpers;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Ajial.Application.Service;

public class AdminConsultationService : IAdminConsultationService
{
    private readonly IUnitOfWork _unitOfWork;

    public AdminConsultationService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    // ── مراجعة المدفوعات ───────────────────────────────────────────────────────

    public async Task<ApiResponse<AdminPaymentListResponse>> GetPaymentsAsync(int? status, int page, int pageSize)
    {
        try
        {
            var normalizedPage = Math.Max(page, 1);
            var normalizedSize = Math.Clamp(pageSize, 1, 100);

            var query = (await _unitOfWork.Payments.GetAllAsync()).AsEnumerable();
            if (status.HasValue)
            {
                if (!Enum.IsDefined(typeof(PaymentStatus), status.Value))
                    return ApiResponse<AdminPaymentListResponse>.FailureResponse("حالة غير صحيحة");
                query = query.Where(p => (int)p.Status == status.Value);
            }

            var ordered = query.OrderByDescending(p => p.CreatedAt).ToList();
            var total = ordered.Count;
            var pageItems = ordered.Skip((normalizedPage - 1) * normalizedSize).Take(normalizedSize).ToList();

            var (bookings, specialists, parentNames) = await LoadLookupsAsync(pageItems);

            var items = pageItems.Select(p =>
            {
                bookings.TryGetValue(p.BookingId, out var b);
                Specialist? sp = b != null && specialists.TryGetValue(b.SpecialistId, out var s) ? s : null;
                return new AdminPaymentListItemDto
                {
                    PaymentId = p.Id,
                    BookingId = p.BookingId,
                    ParentName = parentNames.GetValueOrDefault(p.ParentId, string.Empty),
                    DoctorName = sp?.User?.FullName ?? string.Empty,
                    ServiceTypeAr = b != null ? ConsultationLabels.ServiceTypeAr(b.ServiceType) : string.Empty,
                    Amount = p.Amount,
                    Method = ConsultationLabels.PaymentMethodKey(p.Method),
                    MethodAr = ConsultationLabels.PaymentMethodAr(p.Method),
                    Status = ConsultationLabels.PaymentStatusKey(p.Status),
                    StatusAr = ConsultationLabels.PaymentStatusAr(p.Status),
                    CreatedAt = p.CreatedAt
                };
            }).ToList();

            return ApiResponse<AdminPaymentListResponse>.SuccessResponse(new AdminPaymentListResponse
            {
                TotalCount = total,
                Page = normalizedPage,
                PageSize = normalizedSize,
                Items = items
            }, "تم جلب قائمة المدفوعات بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<AdminPaymentListResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<AdminPaymentDetailResponse>> GetPaymentDetailAsync(Guid paymentId)
    {
        try
        {
            var payment = await _unitOfWork.Payments.GetByIdAsync(paymentId);
            if (payment == null)
                return ApiResponse<AdminPaymentDetailResponse>.FailureResponse("لم يتم العثور على عملية الدفع");

            var booking = await _unitOfWork.Bookings.GetByIdAsync(payment.BookingId);
            var specialist = booking != null
                ? await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.Id == booking.SpecialistId, "User")
                : null;
            var parentName = await ResolveParentNameAsync(payment.ParentId);
            var patientName = booking != null ? await ResolvePatientNameAsync(booking) : string.Empty;

            return ApiResponse<AdminPaymentDetailResponse>.SuccessResponse(new AdminPaymentDetailResponse
            {
                PaymentId = payment.Id,
                BookingId = payment.BookingId,
                ParentName = parentName,
                PatientName = patientName,
                DoctorName = specialist?.User?.FullName ?? string.Empty,
                Specialization = specialist?.Specialization ?? string.Empty,
                ServiceTypeAr = booking != null ? ConsultationLabels.ServiceTypeAr(booking.ServiceType) : string.Empty,
                AppointmentDate = booking != null ? booking.AppointmentDate.ToString("yyyy-MM-dd") : string.Empty,
                StartTime = booking?.StartTime != null ? WorkingHoursHelper.Format(booking.StartTime.Value) : null,
                EndTime = booking?.EndTime != null ? WorkingHoursHelper.Format(booking.EndTime.Value) : null,
                Amount = payment.Amount,
                Method = ConsultationLabels.PaymentMethodKey(payment.Method),
                MethodAr = ConsultationLabels.PaymentMethodAr(payment.Method),
                ReceiptImageUrl = payment.ReceiptImageUrl,
                Status = ConsultationLabels.PaymentStatusKey(payment.Status),
                StatusAr = ConsultationLabels.PaymentStatusAr(payment.Status),
                RejectionReason = payment.RejectionReason,
                BookingStatus = booking != null ? ConsultationLabels.BookingStatusKey(booking.Status) : string.Empty,
                BookingStatusAr = booking != null ? ConsultationLabels.BookingStatusAr(booking.Status) : string.Empty,
                CreatedAt = payment.CreatedAt
            }, "تم جلب تفاصيل الدفع بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<AdminPaymentDetailResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<PaymentStatusChangeResponse>> ApprovePaymentAsync(Guid paymentId, Guid adminUserId)
    {
        try
        {
            var payment = await _unitOfWork.Payments.GetByIdAsync(paymentId);
            if (payment == null)
                return ApiResponse<PaymentStatusChangeResponse>.FailureResponse("لم يتم العثور على عملية الدفع");
            if (payment.Status != PaymentStatus.Pending)
                return ApiResponse<PaymentStatusChangeResponse>.FailureResponse("لا يمكن قبول الدفع - ليس قيد المراجعة");

            var booking = await _unitOfWork.Bookings.GetByIdAsync(payment.BookingId);
            if (booking == null)
                return ApiResponse<PaymentStatusChangeResponse>.FailureResponse("لم يتم العثور على الحجز المرتبط");

            payment.Status = PaymentStatus.Approved;
            payment.RejectionReason = null;
            payment.ReviewedAt = DateTime.UtcNow;
            payment.ReviewedByUserId = adminUserId;
            await _unitOfWork.Payments.UpdateAsync(payment);

            booking.Status = BookingStatus.Confirmed;
            booking.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Bookings.UpdateAsync(booking);

            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<PaymentStatusChangeResponse>.SuccessResponse(
                MapStatusChange(payment, booking), "تم قبول الدفع وتأكيد الحجز");
        }
        catch (Exception ex)
        {
            return ApiResponse<PaymentStatusChangeResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<PaymentStatusChangeResponse>> RejectPaymentAsync(Guid paymentId, Guid adminUserId, RejectPaymentRequest request)
    {
        try
        {
            var payment = await _unitOfWork.Payments.GetByIdAsync(paymentId);
            if (payment == null)
                return ApiResponse<PaymentStatusChangeResponse>.FailureResponse("لم يتم العثور على عملية الدفع");
            if (payment.Status != PaymentStatus.Pending)
                return ApiResponse<PaymentStatusChangeResponse>.FailureResponse("لا يمكن رفض الدفع - ليس قيد المراجعة");

            var booking = await _unitOfWork.Bookings.GetByIdAsync(payment.BookingId);
            if (booking == null)
                return ApiResponse<PaymentStatusChangeResponse>.FailureResponse("لم يتم العثور على الحجز المرتبط");

            payment.Status = PaymentStatus.Rejected;
            payment.RejectionReason = request.Reason;
            payment.ReviewedAt = DateTime.UtcNow;
            payment.ReviewedByUserId = adminUserId;
            await _unitOfWork.Payments.UpdateAsync(payment);

            booking.Status = BookingStatus.Rejected;
            booking.RejectionReason = request.Reason;
            booking.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Bookings.UpdateAsync(booking);

            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<PaymentStatusChangeResponse>.SuccessResponse(
                MapStatusChange(payment, booking), "تم رفض الدفع");
        }
        catch (Exception ex)
        {
            return ApiResponse<PaymentStatusChangeResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── إعدادات الدفع ──────────────────────────────────────────────────────────

    public async Task<ApiResponse<PaymentSettingsResponse>> GetPaymentSettingsAsync()
    {
        try
        {
            var map = (await _unitOfWork.PaymentSettings.GetAllAsync()).ToDictionary(s => s.Key, s => s.Value);
            return ApiResponse<PaymentSettingsResponse>.SuccessResponse(new PaymentSettingsResponse
            {
                VodafoneCashNumber = map.GetValueOrDefault(ConsultationLabels.VodafoneCashKey, ConsultationLabels.DefaultWalletNumber),
                InstaPayNumber = map.GetValueOrDefault(ConsultationLabels.InstaPayKey, ConsultationLabels.DefaultWalletNumber)
            }, "تم جلب إعدادات الدفع بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<PaymentSettingsResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<PaymentSettingsResponse>> UpdatePaymentSettingsAsync(Guid adminUserId, UpdatePaymentSettingsRequest request)
    {
        try
        {
            if (!string.IsNullOrWhiteSpace(request.VodafoneCashNumber))
                await UpsertSettingAsync(ConsultationLabels.VodafoneCashKey, request.VodafoneCashNumber.Trim(), adminUserId);
            if (!string.IsNullOrWhiteSpace(request.InstaPayNumber))
                await UpsertSettingAsync(ConsultationLabels.InstaPayKey, request.InstaPayNumber.Trim(), adminUserId);

            await _unitOfWork.SaveChangesAsync();
            return await GetPaymentSettingsAsync();
        }
        catch (Exception ex)
        {
            return ApiResponse<PaymentSettingsResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private async Task UpsertSettingAsync(string key, string value, Guid adminUserId)
    {
        var existing = await _unitOfWork.PaymentSettings.GetFirstOrDefaultAsync(s => s.Key == key);
        if (existing == null)
        {
            await _unitOfWork.PaymentSettings.AddAsync(new PaymentSetting
            {
                Key = key,
                Value = value,
                UpdatedAt = DateTime.UtcNow,
                UpdatedByUserId = adminUserId
            });
        }
        else
        {
            existing.Value = value;
            existing.UpdatedAt = DateTime.UtcNow;
            existing.UpdatedByUserId = adminUserId;
            await _unitOfWork.PaymentSettings.UpdateAsync(existing);
        }
    }

    private async Task<(Dictionary<Guid, Booking> bookings, Dictionary<Guid, Specialist> specialists, Dictionary<Guid, string> parentNames)>
        LoadLookupsAsync(List<Payment> payments)
    {
        var bookingIds = payments.Select(p => p.BookingId).ToHashSet();
        var parentIds = payments.Select(p => p.ParentId).ToHashSet();

        var bookings = (await _unitOfWork.Bookings.FindAsync(b => bookingIds.Contains(b.Id))).ToDictionary(b => b.Id);
        var specialistIds = bookings.Values.Select(b => b.SpecialistId).ToHashSet();
        var specialists = (await _unitOfWork.Specialists.GetAllAsync(q => q.Include(s => s.User)))
            .Where(s => specialistIds.Contains(s.Id))
            .ToDictionary(s => s.Id);

        var parents = (await _unitOfWork.Parents.FindAsync(p => parentIds.Contains(p.Id))).ToList();
        var userIds = parents.Select(p => p.UserId).ToHashSet();
        var users = (await _unitOfWork.Users.GetAllAsync()).Where(u => userIds.Contains(u.Id)).ToDictionary(u => u.Id);
        var parentNames = parents.ToDictionary(p => p.Id, p => users.GetValueOrDefault(p.UserId)?.FullName ?? string.Empty);

        return (bookings, specialists, parentNames);
    }

    private async Task<string> ResolveParentNameAsync(Guid parentId)
    {
        var parent = await _unitOfWork.Parents.GetByIdAsync(parentId);
        if (parent == null) return string.Empty;
        var user = await _unitOfWork.Users.GetByIdAsync(parent.UserId);
        return user?.FullName ?? string.Empty;
    }

    private async Task<string> ResolvePatientNameAsync(Booking booking)
    {
        if (!booking.ChildId.HasValue)
            return await ResolveParentNameAsync(booking.ParentId);
        var child = await _unitOfWork.Children.GetByIdAsync(booking.ChildId.Value);
        return child?.FullName ?? string.Empty;
    }

    private static PaymentStatusChangeResponse MapStatusChange(Payment p, Booking b) => new()
    {
        PaymentId = p.Id,
        BookingId = b.Id,
        PaymentStatus = ConsultationLabels.PaymentStatusKey(p.Status),
        PaymentStatusAr = ConsultationLabels.PaymentStatusAr(p.Status),
        BookingStatus = ConsultationLabels.BookingStatusKey(b.Status),
        BookingStatusAr = ConsultationLabels.BookingStatusAr(b.Status)
    };
}
