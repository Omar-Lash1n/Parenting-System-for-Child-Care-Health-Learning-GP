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
                    ReceiptImageUrl = p.ReceiptImageUrl,
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

    // ── الحجوزات الملغاة (متابعة استرداد المبالغ يدوياً) ─────────────────────────

    public async Task<ApiResponse<AdminCancellationListResponse>> GetCancellationsAsync(int page, int pageSize)
    {
        try
        {
            var normalizedPage = Math.Max(page, 1);
            var normalizedSize = Math.Clamp(pageSize, 1, 100);

            var cancelled = (await _unitOfWork.Bookings.FindAsync(b => b.Status == BookingStatus.Cancelled))
                .OrderByDescending(b => b.CancelledAt ?? b.UpdatedAt ?? b.CreatedAt)
                .ToList();

            var total = cancelled.Count;
            if (total == 0)
                return ApiResponse<AdminCancellationListResponse>.SuccessResponse(new AdminCancellationListResponse
                {
                    Page = normalizedPage,
                    PageSize = normalizedSize
                }, "لا توجد حجوزات ملغاة");

            var pageItems = cancelled.Skip((normalizedPage - 1) * normalizedSize).Take(normalizedSize).ToList();

            // إيصالات الدفع الأصلية المرتبطة بكل حجز ملغى
            var bookingIds = pageItems.Select(b => b.Id).ToHashSet();
            var payments = (await _unitOfWork.Payments.FindAsync(p => bookingIds.Contains(p.BookingId)))
                .ToDictionary(p => p.BookingId);

            // أطباء + أولياء أمور + أطفال (تحميل مجمّع للأسماء)
            var specialistIds = pageItems.Select(b => b.SpecialistId).ToHashSet();
            var specialists = (await _unitOfWork.Specialists.GetAllAsync(q => q.Include(s => s.User)))
                .Where(s => specialistIds.Contains(s.Id))
                .ToDictionary(s => s.Id);

            var parentIds = pageItems.Select(b => b.ParentId).ToHashSet();
            var parents = (await _unitOfWork.Parents.FindAsync(p => parentIds.Contains(p.Id))).ToList();
            var userIds = parents.Select(p => p.UserId).ToHashSet();
            var users = (await _unitOfWork.Users.GetAllAsync()).Where(u => userIds.Contains(u.Id)).ToDictionary(u => u.Id);
            var parentNames = parents.ToDictionary(p => p.Id, p => users.GetValueOrDefault(p.UserId)?.FullName ?? string.Empty);

            var childIds = pageItems.Where(b => b.ChildId.HasValue).Select(b => b.ChildId!.Value).ToHashSet();
            var children = childIds.Count > 0
                ? (await _unitOfWork.Children.FindAsync(c => childIds.Contains(c.Id))).ToDictionary(c => c.Id, c => c.FullName)
                : new Dictionary<Guid, string>();

            var items = pageItems.Select(b =>
            {
                payments.TryGetValue(b.Id, out var pay);
                specialists.TryGetValue(b.SpecialistId, out var sp);
                var parentName = parentNames.GetValueOrDefault(b.ParentId, string.Empty);
                var patientName = b.ChildId.HasValue ? children.GetValueOrDefault(b.ChildId.Value, string.Empty) : parentName;

                return new AdminCancellationItemDto
                {
                    BookingId = b.Id,
                    ParentName = parentName,
                    PatientName = patientName,
                    DoctorName = sp?.User?.FullName ?? string.Empty,
                    ServiceTypeAr = ConsultationLabels.ServiceTypeAr(b.ServiceType),
                    AppointmentDate = b.AppointmentDate.ToString("yyyy-MM-dd"),
                    BasePrice = b.Price,
                    CancellationFeePercent = ConsultationLabels.CancellationFeePercent,
                    CancellationFeeAmount = b.CancellationFeeAmount ?? 0m,
                    RefundAmount = b.RefundAmount ?? 0m,
                    PaymentMethod = pay != null ? ConsultationLabels.PaymentMethodKey(pay.Method) : null,
                    PaymentMethodAr = pay != null ? ConsultationLabels.PaymentMethodAr(pay.Method) : null,
                    PaidAmount = pay?.Amount,
                    ReceiptImageUrl = pay?.ReceiptImageUrl,
                    PaymentStatusAr = pay != null ? ConsultationLabels.PaymentStatusAr(pay.Status) : null,
                    CancelledAt = b.CancelledAt
                };
            }).ToList();

            return ApiResponse<AdminCancellationListResponse>.SuccessResponse(new AdminCancellationListResponse
            {
                TotalCount = total,
                Page = normalizedPage,
                PageSize = normalizedSize,
                Items = items
            }, "تم جلب قائمة الحجوزات الملغاة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<AdminCancellationListResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── تقييمات الجلسات ───────────────────────────────────────────────────────

    public async Task<ApiResponse<AdminRatingListResponse>> GetRatingsAsync(Guid? specialistId, bool? hadIssue, int page, int pageSize)
    {
        try
        {
            var normalizedPage = Math.Max(page, 1);
            var normalizedSize = Math.Clamp(pageSize, 1, 100);

            var ratings = (await _unitOfWork.SessionRatings.GetAllAsync()).ToList();
            if (ratings.Count == 0)
                return ApiResponse<AdminRatingListResponse>.SuccessResponse(new AdminRatingListResponse
                {
                    Page = normalizedPage,
                    PageSize = normalizedSize
                }, "لا توجد تقييمات");

            var bookingIds = ratings.Select(r => r.BookingId).ToHashSet();
            var bookings = (await _unitOfWork.Bookings.FindAsync(b => bookingIds.Contains(b.Id))).ToDictionary(b => b.Id);

            // فلتر بالطبيب
            if (specialistId.HasValue)
                ratings = ratings.Where(r => bookings.TryGetValue(r.BookingId, out var b) && b.SpecialistId == specialistId.Value).ToList();

            // فلتر من أبلغ عن مشكلة
            if (hadIssue.HasValue)
                ratings = ratings.Where(r => r.HadIssue == hadIssue.Value).ToList();

            var ordered = ratings.OrderByDescending(r => r.CreatedAt).ToList();
            var total = ordered.Count;
            var average = total > 0 ? Math.Round(ordered.Average(r => r.Rating), 2) : 0;
            var pageItems = ordered.Skip((normalizedPage - 1) * normalizedSize).Take(normalizedSize).ToList();

            var items = await BuildRatingItemsAsync(pageItems, bookings);

            return ApiResponse<AdminRatingListResponse>.SuccessResponse(new AdminRatingListResponse
            {
                TotalCount = total,
                Page = normalizedPage,
                PageSize = normalizedSize,
                AverageRating = average,
                Items = items
            }, "تم جلب تقييمات الجلسات بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<AdminRatingListResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<AdminDoctorRatingSummaryResponse>> GetDoctorRatingsSummaryAsync()
    {
        try
        {
            var ratings = (await _unitOfWork.SessionRatings.GetAllAsync()).ToList();
            if (ratings.Count == 0)
                return ApiResponse<AdminDoctorRatingSummaryResponse>.SuccessResponse(
                    new AdminDoctorRatingSummaryResponse(), "لا توجد تقييمات");

            var bookingIds = ratings.Select(r => r.BookingId).ToHashSet();
            var bookings = (await _unitOfWork.Bookings.FindAsync(b => bookingIds.Contains(b.Id))).ToDictionary(b => b.Id);

            // اربط كل تقييم بطبيبه عبر الحجز
            var byDoctor = ratings
                .Select(r => (Rating: r, SpecialistId: bookings.TryGetValue(r.BookingId, out var b) ? b.SpecialistId : (Guid?)null))
                .Where(x => x.SpecialistId.HasValue)
                .GroupBy(x => x.SpecialistId!.Value)
                .ToList();

            var specialistIds = byDoctor.Select(g => g.Key).ToHashSet();
            var specialists = (await _unitOfWork.Specialists.GetAllAsync(q => q.Include(s => s.User)))
                .Where(s => specialistIds.Contains(s.Id))
                .ToDictionary(s => s.Id);

            var doctors = byDoctor.Select(g =>
            {
                var rs = g.Select(x => x.Rating).ToList();
                specialists.TryGetValue(g.Key, out var sp);
                return new AdminDoctorRatingDto
                {
                    SpecialistId = g.Key,
                    DoctorName = sp?.User?.FullName ?? string.Empty,
                    Specialization = sp?.Specialization ?? string.Empty,
                    PhotoUrl = sp?.PersonalPhotoUrl,
                    AverageRating = Math.Round(rs.Average(r => r.Rating), 2),
                    TotalRatings = rs.Count,
                    FiveStars = rs.Count(r => r.Rating == 5),
                    FourStars = rs.Count(r => r.Rating == 4),
                    ThreeStars = rs.Count(r => r.Rating == 3),
                    TwoStars = rs.Count(r => r.Rating == 2),
                    OneStar = rs.Count(r => r.Rating == 1),
                    WouldBookAgainCount = rs.Count(r => r.WouldBookAgain),
                    IssuesCount = rs.Count(r => r.HadIssue)
                };
            })
            .OrderByDescending(d => d.AverageRating)
            .ThenByDescending(d => d.TotalRatings)
            .ToList();

            return ApiResponse<AdminDoctorRatingSummaryResponse>.SuccessResponse(new AdminDoctorRatingSummaryResponse
            {
                DoctorCount = doctors.Count,
                TotalRatings = ratings.Count,
                OverallAverageRating = Math.Round(ratings.Average(r => r.Rating), 2),
                Doctors = doctors
            }, "تم جلب ملخص تقييمات الأطباء بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<AdminDoctorRatingSummaryResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    /// <summary>يحوّل قائمة تقييمات الى DTOs مع أسماء الطبيب/ولي الأمر/المريض (تحميل مجمّع للأسماء).</summary>
    private async Task<List<AdminRatingItemDto>> BuildRatingItemsAsync(List<SessionRating> ratings, Dictionary<Guid, Booking> bookings)
    {
        var relatedBookings = ratings
            .Select(r => bookings.GetValueOrDefault(r.BookingId))
            .Where(b => b != null)
            .Select(b => b!)
            .ToList();

        var specialistIds = relatedBookings.Select(b => b.SpecialistId).ToHashSet();
        var specialists = (await _unitOfWork.Specialists.GetAllAsync(q => q.Include(s => s.User)))
            .Where(s => specialistIds.Contains(s.Id))
            .ToDictionary(s => s.Id);

        // أسماء أولياء الأمور
        var parentIds = ratings.Select(r => r.ParentId).ToHashSet();
        var parents = (await _unitOfWork.Parents.FindAsync(p => parentIds.Contains(p.Id))).ToList();
        var parentUserIds = parents.Select(p => p.UserId).ToHashSet();
        var users = (await _unitOfWork.Users.GetAllAsync()).Where(u => parentUserIds.Contains(u.Id)).ToDictionary(u => u.Id);
        var parentNames = parents.ToDictionary(p => p.Id, p => users.GetValueOrDefault(p.UserId)?.FullName ?? string.Empty);

        // أسماء المرضى (الأطفال)
        var childIds = relatedBookings.Where(b => b.ChildId.HasValue).Select(b => b.ChildId!.Value).ToHashSet();
        var children = childIds.Count > 0
            ? (await _unitOfWork.Children.FindAsync(c => childIds.Contains(c.Id))).ToDictionary(c => c.Id, c => c.FullName)
            : new Dictionary<Guid, string>();

        return ratings.Select(r =>
        {
            bookings.TryGetValue(r.BookingId, out var b);
            Specialist? sp = b != null && specialists.TryGetValue(b.SpecialistId, out var s) ? s : null;
            var parentName = parentNames.GetValueOrDefault(r.ParentId, string.Empty);
            var patientName = b == null
                ? string.Empty
                : b.ChildId.HasValue ? children.GetValueOrDefault(b.ChildId.Value, string.Empty) : parentName;

            return new AdminRatingItemDto
            {
                RatingId = r.Id,
                BookingId = r.BookingId,
                SpecialistId = b?.SpecialistId ?? Guid.Empty,
                DoctorName = sp?.User?.FullName ?? string.Empty,
                Specialization = sp?.Specialization ?? string.Empty,
                ParentName = parentName,
                PatientName = patientName,
                ServiceTypeAr = b != null ? ConsultationLabels.ServiceTypeAr(b.ServiceType) : string.Empty,
                AppointmentDate = b != null ? b.AppointmentDate.ToString("yyyy-MM-dd") : string.Empty,
                Rating = r.Rating,
                WouldBookAgain = r.WouldBookAgain,
                WouldBookAgainAr = r.WouldBookAgain ? "نعم, عند الحاجة" : "لا, جلسة ضعيفة ولم نستفد منها",
                HadIssue = r.HadIssue,
                IssueDescription = r.IssueDescription,
                StarsAwarded = r.StarsAwarded,
                CreatedAt = r.CreatedAt
            };
        }).ToList();
    }

    // ── بلاغات المشاكل (الإبلاغ عن مشكلة) ───────────────────────────────────────

    public async Task<ApiResponse<AdminProblemReportListResponse>> GetProblemReportsAsync(Guid? specialistId, int? status, int? category, int page, int pageSize)
    {
        try
        {
            var normalizedPage = Math.Max(page, 1);
            var normalizedSize = Math.Clamp(pageSize, 1, 100);

            var reports = (await _unitOfWork.ProblemReports.GetAllAsync()).AsEnumerable();

            if (specialistId.HasValue)
                reports = reports.Where(r => r.SpecialistId == specialistId.Value);

            if (status.HasValue)
            {
                if (!Enum.IsDefined(typeof(ProblemReportStatus), status.Value))
                    return ApiResponse<AdminProblemReportListResponse>.FailureResponse("حالة غير صحيحة");
                reports = reports.Where(r => (int)r.Status == status.Value);
            }

            if (category.HasValue)
            {
                if (!Enum.IsDefined(typeof(ProblemReportCategory), category.Value))
                    return ApiResponse<AdminProblemReportListResponse>.FailureResponse("نوع مشكلة غير صحيح");
                reports = reports.Where(r => (int)r.Category == category.Value);
            }

            var ordered = reports.OrderByDescending(r => r.CreatedAt).ToList();
            var total = ordered.Count;
            var newCount = ordered.Count(r => r.Status == ProblemReportStatus.New);
            var pageItems = ordered.Skip((normalizedPage - 1) * normalizedSize).Take(normalizedSize).ToList();

            var items = await BuildProblemReportItemsAsync(pageItems);

            return ApiResponse<AdminProblemReportListResponse>.SuccessResponse(new AdminProblemReportListResponse
            {
                TotalCount = total,
                Page = normalizedPage,
                PageSize = normalizedSize,
                NewCount = newCount,
                Items = items
            }, "تم جلب بلاغات المشاكل بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<AdminProblemReportListResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<AdminProblemReportItemDto>> GetProblemReportDetailAsync(Guid reportId)
    {
        try
        {
            var report = await _unitOfWork.ProblemReports.GetByIdAsync(reportId);
            if (report == null)
                return ApiResponse<AdminProblemReportItemDto>.FailureResponse("لم يتم العثور على البلاغ");

            var items = await BuildProblemReportItemsAsync(new List<ProblemReport> { report });
            return ApiResponse<AdminProblemReportItemDto>.SuccessResponse(items[0], "تم جلب تفاصيل البلاغ بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<AdminProblemReportItemDto>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<AdminProblemReportItemDto>> UpdateProblemReportStatusAsync(Guid reportId, Guid adminUserId, UpdateProblemReportStatusRequest request)
    {
        try
        {
            if (!Enum.IsDefined(typeof(ProblemReportStatus), request.Status))
                return ApiResponse<AdminProblemReportItemDto>.FailureResponse("حالة غير صحيحة");

            var report = await _unitOfWork.ProblemReports.GetByIdAsync(reportId);
            if (report == null)
                return ApiResponse<AdminProblemReportItemDto>.FailureResponse("لم يتم العثور على البلاغ");

            report.Status = (ProblemReportStatus)request.Status;
            report.AdminNote = string.IsNullOrWhiteSpace(request.AdminNote) ? null : request.AdminNote.Trim();
            report.ReviewedAt = DateTime.UtcNow;
            report.ReviewedByUserId = adminUserId;
            await _unitOfWork.ProblemReports.UpdateAsync(report);
            await _unitOfWork.SaveChangesAsync();

            var items = await BuildProblemReportItemsAsync(new List<ProblemReport> { report });
            return ApiResponse<AdminProblemReportItemDto>.SuccessResponse(items[0], "تم تحديث حالة البلاغ بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<AdminProblemReportItemDto>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    /// <summary>يحوّل قائمة بلاغات الى DTOs مع أسماء الطبيب/ولي الأمر وتفاصيل الجلسة المرتبطة (تحميل مجمّع).</summary>
    private async Task<List<AdminProblemReportItemDto>> BuildProblemReportItemsAsync(List<ProblemReport> reports)
    {
        if (reports.Count == 0) return new List<AdminProblemReportItemDto>();

        // أطباء
        var specialistIds = reports.Select(r => r.SpecialistId).ToHashSet();
        var specialists = (await _unitOfWork.Specialists.GetAllAsync(q => q.Include(s => s.User)))
            .Where(s => specialistIds.Contains(s.Id))
            .ToDictionary(s => s.Id);

        // أسماء أولياء الأمور
        var parentIds = reports.Select(r => r.ParentId).ToHashSet();
        var parents = (await _unitOfWork.Parents.FindAsync(p => parentIds.Contains(p.Id))).ToList();
        var userIds = parents.Select(p => p.UserId).ToHashSet();
        var users = (await _unitOfWork.Users.GetAllAsync()).Where(u => userIds.Contains(u.Id)).ToDictionary(u => u.Id);
        var parentNames = parents.ToDictionary(p => p.Id, p => users.GetValueOrDefault(p.UserId)?.FullName ?? string.Empty);

        // الحجوزات المرتبطة (اختياري)
        var bookingIds = reports.Where(r => r.BookingId.HasValue).Select(r => r.BookingId!.Value).ToHashSet();
        var bookings = bookingIds.Count > 0
            ? (await _unitOfWork.Bookings.FindAsync(b => bookingIds.Contains(b.Id))).ToDictionary(b => b.Id)
            : new Dictionary<Guid, Booking>();

        return reports.Select(r =>
        {
            specialists.TryGetValue(r.SpecialistId, out var sp);
            Booking? b = r.BookingId.HasValue && bookings.TryGetValue(r.BookingId.Value, out var bk) ? bk : null;

            return new AdminProblemReportItemDto
            {
                ReportId = r.Id,
                SpecialistId = r.SpecialistId,
                DoctorName = sp?.User?.FullName ?? string.Empty,
                Specialization = sp?.Specialization ?? string.Empty,
                DoctorPhotoUrl = sp?.PersonalPhotoUrl,
                ParentId = r.ParentId,
                ParentName = parentNames.GetValueOrDefault(r.ParentId, string.Empty),
                BookingId = r.BookingId,
                ServiceTypeAr = b != null ? ConsultationLabels.ServiceTypeAr(b.ServiceType) : null,
                AppointmentDate = b != null ? b.AppointmentDate.ToString("yyyy-MM-dd") : null,
                Category = (int)r.Category,
                CategoryKey = ConsultationLabels.ProblemCategoryKey(r.Category),
                CategoryAr = ConsultationLabels.ProblemCategoryAr(r.Category),
                Description = r.Description,
                StatusValue = (int)r.Status,
                Status = ConsultationLabels.ProblemStatusKey(r.Status),
                StatusAr = ConsultationLabels.ProblemStatusAr(r.Status),
                AdminNote = r.AdminNote,
                ReviewedAt = r.ReviewedAt,
                CreatedAt = r.CreatedAt
            };
        }).ToList();
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
