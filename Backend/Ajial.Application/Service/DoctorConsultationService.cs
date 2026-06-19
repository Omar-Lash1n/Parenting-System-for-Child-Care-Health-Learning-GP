using System.Globalization;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Consultation;
using Ajial.Application.Helpers;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Service;

public class DoctorConsultationService : IDoctorConsultationService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMeetingService _meetingService;

    /// <summary>يُسمح للطبيب ببدء الجلسة قبل موعدها بـ 5 دقائق كحد أقصى.</summary>
    private const int StartLeadMinutes = 5;

    /// <summary>يُسمح ببدء الجلسة حتى ساعتين بعد نهايتها (مرونة للحالات المتأخرة).</summary>
    private const int StartGraceMinutesAfterEnd = 120;

    /// <summary>الحالات التي يعتبرها الطبيب "محجوزة" ويستطيع فتح تفاصيلها (تم الدفع وتأكيد الحجز).</summary>
    private static readonly BookingStatus[] DoctorVisibleStatuses =
        { BookingStatus.Confirmed, BookingStatus.Completed };

    public DoctorConsultationService(IUnitOfWork unitOfWork, IMeetingService meetingService)
    {
        _unitOfWork = unitOfWork;
        _meetingService = meetingService;
    }

    // ── المواعيد المحجوزة (شاشة مواعيد اليوم + تقويم الشهر) ──────────────────────

    public async Task<ApiResponse<DoctorDaySlotsResponse>> GetDaySlotsAsync(Guid userId, string date)
    {
        try
        {
            var (specialist, error) = await ResolveSpecialistAsync<DoctorDaySlotsResponse>(userId);
            if (error != null) return error;

            if (!DateTime.TryParseExact(date, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var day))
                return ApiResponse<DoctorDaySlotsResponse>.FailureResponse("تاريخ غير صحيح، الصيغة المطلوبة yyyy-MM-dd");
            day = day.Date;

            var response = new DoctorDaySlotsResponse { Date = date };

            var remote = await GetApprovedRemoteAsync(specialist!.Id);
            if (remote == null || !remote.SessionDurationMinutes.HasValue)
                return ApiResponse<DoctorDaySlotsResponse>.SuccessResponse(response, "لا توجد خدمة كشف عن بعد متاحة");

            // حجوزات هذا اليوم المرئية للطبيب (مع إكمال أي جلسة انتهى وقتها تلقائياً).
            var dayBookings = (await _unitOfWork.Bookings.FindAsync(b =>
                b.SpecialistId == specialist.Id &&
                b.ServiceType == BookingServiceType.RemoteConsultation &&
                b.AppointmentDate == day)).ToList();
            await AutoCompleteEndedRemoteSessionsAsync(dayBookings);

            var bookedByStart = dayBookings
                .Where(b => DoctorVisibleStatuses.Contains(b.Status) && b.StartTime.HasValue)
                .GroupBy(b => b.StartTime!.Value)
                .ToDictionary(g => g.Key, g => g.OrderByDescending(b => b.CreatedAt).First());

            var childMap = await LoadChildNamesAsync(bookedByStart.Values);

            var slots = WorkingHoursHelper.GenerateRemoteSlots(
                remote.WorkingHoursJson, day, remote.SessionDurationMinutes.Value, remote.WaitingPeriodMinutes ?? 0);

            foreach (var (start, end) in slots)
            {
                var slot = new DoctorSlotDto
                {
                    StartTime = WorkingHoursHelper.Format(start),
                    EndTime = WorkingHoursHelper.Format(end)
                };

                if (bookedByStart.TryGetValue(start, out var booking))
                {
                    slot.IsBooked = true;
                    slot.BookingId = booking.Id;
                    slot.Status = ConsultationLabels.BookingStatusKey(booking.Status);
                    slot.StatusAr = SessionBadgeAr(booking.Status);
                    slot.PatientName = await ResolvePatientNameAsync(booking, childMap);
                }

                response.Slots.Add(slot);
            }

            response.IsAvailable = response.Slots.Count > 0;
            return ApiResponse<DoctorDaySlotsResponse>.SuccessResponse(response, "تم جلب مواعيد اليوم بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<DoctorDaySlotsResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<DoctorCalendarResponse>> GetMonthBookingsAsync(Guid userId, string month)
    {
        try
        {
            var (specialist, error) = await ResolveSpecialistAsync<DoctorCalendarResponse>(userId);
            if (error != null) return error;

            if (!DateTime.TryParseExact(month, "yyyy-MM", CultureInfo.InvariantCulture, DateTimeStyles.None, out var monthStart))
                return ApiResponse<DoctorCalendarResponse>.FailureResponse("صيغة الشهر غير صحيحة، المطلوب yyyy-MM");
            monthStart = new DateTime(monthStart.Year, monthStart.Month, 1);
            var monthEnd = monthStart.AddMonths(1);

            var bookings = (await _unitOfWork.Bookings.FindAsync(b =>
                b.SpecialistId == specialist!.Id &&
                b.ServiceType == BookingServiceType.RemoteConsultation &&
                b.AppointmentDate >= monthStart &&
                b.AppointmentDate < monthEnd)).ToList();
            await AutoCompleteEndedRemoteSessionsAsync(bookings);

            var dates = bookings
                .Where(b => DoctorVisibleStatuses.Contains(b.Status))
                .Select(b => b.AppointmentDate.Date)
                .Distinct()
                .OrderBy(d => d)
                .Select(d => d.ToString("yyyy-MM-dd"))
                .ToList();

            return ApiResponse<DoctorCalendarResponse>.SuccessResponse(
                new DoctorCalendarResponse { Month = month, BookedDates = dates }, "تم جلب أيام الحجوزات بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<DoctorCalendarResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── تفاصيل الحجز (الأعراض والشكوى + المرفقات + الملف الطبي) ──────────────────

    public async Task<ApiResponse<DoctorBookingDetailResponse>> GetBookingDetailAsync(Guid userId, Guid bookingId)
    {
        try
        {
            var (booking, error) = await ResolveBookingAsync<DoctorBookingDetailResponse>(userId, bookingId, "Attachments");
            if (error != null) return error;

            await AutoCompleteEndedRemoteSessionsAsync(new[] { booking! });

            var detail = new DoctorBookingDetailResponse
            {
                BookingId = booking!.Id,
                Status = ConsultationLabels.BookingStatusKey(booking.Status),
                StatusAr = SessionBadgeAr(booking.Status),
                ServiceType = ConsultationLabels.ServiceTypeKey(booking.ServiceType),
                ServiceTypeAr = ConsultationLabels.ServiceTypeAr(booking.ServiceType),
                AppointmentDate = booking.AppointmentDate.ToString("yyyy-MM-dd"),
                StartTime = booking.StartTime.HasValue ? WorkingHoursHelper.Format(booking.StartTime.Value) : null,
                EndTime = booking.EndTime.HasValue ? WorkingHoursHelper.Format(booking.EndTime.Value) : null,
                DurationMinutes = booking.DurationMinutes,
                Price = booking.Price,
                ChildId = booking.ChildId,
                IsChildPatient = booking.ChildId.HasValue,
                ComplaintDescription = booking.ComplaintDescription,
                ShareMedicalFile = booking.ShareMedicalFile,
                MedicalFileUrl = booking.MedicalFileUrl,
                Attachments = (booking.Attachments ?? new List<BookingAttachment>())
                    .OrderBy(a => a.CreatedAt)
                    .Select(a => new AttachmentDto { Id = a.Id, ImageUrl = a.ImageUrl })
                    .ToList(),
                Session = BuildSessionStatus(booking)
            };

            // بيانات المريض (الطفل أو ولي الأمر نفسه)
            if (booking.ChildId.HasValue)
            {
                var child = await _unitOfWork.Children.GetByIdAsync(booking.ChildId.Value);
                detail.PatientName = child?.FullName ?? string.Empty;
                detail.PatientImageUrl = child?.ProfileImageUrl;
                detail.PatientAge = child?.Age;
                detail.PatientGender = child?.Gender;
            }
            else
            {
                var parent = await _unitOfWork.Parents.GetByIdAsync(booking.ParentId);
                var user = parent != null ? await _unitOfWork.Users.GetByIdAsync(parent.UserId) : null;
                detail.PatientName = user?.FullName ?? string.Empty;
                detail.PatientImageUrl = parent?.ProfileImageUrl;
            }

            return ApiResponse<DoctorBookingDetailResponse>.SuccessResponse(detail, "تم جلب تفاصيل الحجز بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<DoctorBookingDetailResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── حالة الجلسة + بدء/إنهاء الجلسة ──────────────────────────────────────────

    public async Task<ApiResponse<DoctorSessionStatusResponse>> GetSessionStatusAsync(Guid userId, Guid bookingId)
    {
        try
        {
            var (booking, error) = await ResolveBookingAsync<DoctorSessionStatusResponse>(userId, bookingId);
            if (error != null) return error;

            if (booking!.ServiceType != BookingServiceType.RemoteConsultation)
                return ApiResponse<DoctorSessionStatusResponse>.FailureResponse("هذا الحجز ليس جلسة اون لاين");

            await AutoCompleteEndedRemoteSessionsAsync(new[] { booking });

            return ApiResponse<DoctorSessionStatusResponse>.SuccessResponse(
                BuildSessionStatus(booking), "تم جلب حالة الجلسة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<DoctorSessionStatusResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<StartSessionResponse>> StartSessionAsync(Guid userId, Guid bookingId)
    {
        try
        {
            var (booking, error) = await ResolveBookingAsync<StartSessionResponse>(userId, bookingId);
            if (error != null) return error;

            if (booking!.ServiceType != BookingServiceType.RemoteConsultation)
                return ApiResponse<StartSessionResponse>.FailureResponse("هذا الحجز ليس جلسة اون لاين");
            if (booking.Status != BookingStatus.Confirmed)
                return ApiResponse<StartSessionResponse>.FailureResponse("لا يمكن بدء الجلسة في الحالة الحالية للحجز");
            if (!booking.StartTime.HasValue)
                return ApiResponse<StartSessionResponse>.FailureResponse("بيانات موعد الجلسة غير مكتملة");

            var patientName = await ResolvePatientNameAsync(booking);

            // idempotent: إذا بدأت الجلسة مسبقاً أعِد نفس الرابط دون إنشاء اجتماع جديد
            if (booking.SessionStartedAt.HasValue && !string.IsNullOrEmpty(booking.MeetingUrl))
                return ApiResponse<StartSessionResponse>.SuccessResponse(
                    BuildStartResponse(booking, patientName), "الجلسة بدأت بالفعل");

            // التحقق من النافذة الزمنية (لا يمكن البدء قبل الموعد بأكثر من 5 دقائق)
            var now = WorkingHoursHelper.EgyptNow();
            var startLocal = booking.AppointmentDate.Date + booking.StartTime.Value;
            var endLocal = ComputeEndLocal(booking, startLocal);

            if (now < startLocal.AddMinutes(-StartLeadMinutes))
                return ApiResponse<StartSessionResponse>.FailureResponse("لا يمكن بدء الجلسة قبل موعدها");
            if (now > endLocal.AddMinutes(StartGraceMinutesAfterEnd))
                return ApiResponse<StartSessionResponse>.FailureResponse("انتهى وقت هذه الجلسة");

            // إنشاء اجتماع Google Meet
            var title = $"جلسة كشف اون لاين - {patientName}";
            var description = string.IsNullOrWhiteSpace(booking.ComplaintDescription)
                ? "جلسة كشف عن بعد عبر منصة أجيال."
                : $"الشكوى: {booking.ComplaintDescription}";

            MeetingInfo meeting;
            try
            {
                meeting = await _meetingService.CreateMeetingAsync(title, description, startLocal, endLocal);
            }
            catch (Exception ex)
            {
                return ApiResponse<StartSessionResponse>.FailureResponse(
                    "تعذّر إنشاء رابط الجلسة، حاول مرة أخرى", new List<string> { ex.Message });
            }

            booking.MeetingUrl = meeting.JoinUrl;
            booking.MeetingEventId = meeting.EventId;
            booking.SessionStartedAt = DateTime.UtcNow;
            booking.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Bookings.UpdateAsync(booking);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<StartSessionResponse>.SuccessResponse(
                BuildStartResponse(booking, patientName), "تم بدء الجلسة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<StartSessionResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<DoctorSessionStatusResponse>> EndSessionAsync(Guid userId, Guid bookingId)
    {
        try
        {
            var (booking, error) = await ResolveBookingAsync<DoctorSessionStatusResponse>(userId, bookingId);
            if (error != null) return error;

            if (booking!.ServiceType != BookingServiceType.RemoteConsultation)
                return ApiResponse<DoctorSessionStatusResponse>.FailureResponse("هذا الحجز ليس جلسة اون لاين");

            // idempotent: الجلسة منتهية بالفعل
            if (booking.Status == BookingStatus.Completed)
                return ApiResponse<DoctorSessionStatusResponse>.SuccessResponse(
                    BuildSessionStatus(booking), "الجلسة منتهية بالفعل");

            if (booking.Status != BookingStatus.Confirmed)
                return ApiResponse<DoctorSessionStatusResponse>.FailureResponse("لا يمكن إنهاء الجلسة في الحالة الحالية للحجز");
            if (!booking.SessionStartedAt.HasValue || string.IsNullOrEmpty(booking.MeetingUrl))
                return ApiResponse<DoctorSessionStatusResponse>.FailureResponse("لا يمكن إنهاء جلسة لم تبدأ بعد");

            booking.Status = BookingStatus.Completed;
            booking.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Bookings.UpdateAsync(booking);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<DoctorSessionStatusResponse>.SuccessResponse(
                BuildSessionStatus(booking), "تم إنهاء الجلسة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<DoctorSessionStatusResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private async Task<(Specialist? specialist, ApiResponse<T>? error)> ResolveSpecialistAsync<T>(Guid userId)
    {
        var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.UserId == userId);
        if (specialist == null)
            return (null, ApiResponse<T>.FailureResponse("لم يتم العثور على بيانات الطبيب"));
        return (specialist, null);
    }

    private async Task<(Booking? booking, ApiResponse<T>? error)> ResolveBookingAsync<T>(
        Guid userId, Guid bookingId, string? includeProperties = null)
    {
        var (specialist, error) = await ResolveSpecialistAsync<T>(userId);
        if (error != null) return (null, error);

        var booking = includeProperties == null
            ? await _unitOfWork.Bookings.GetByIdAsync(bookingId)
            : await _unitOfWork.Bookings.GetFirstOrDefaultAsync(b => b.Id == bookingId, includeProperties);

        if (booking == null)
            return (null, ApiResponse<T>.FailureResponse("لم يتم العثور على الحجز"));
        if (booking.SpecialistId != specialist!.Id)
            return (null, ApiResponse<T>.FailureResponse("غير مصرح - هذا الحجز لا يخصك"));

        return (booking, null);
    }

    private async Task<RemoteConsultation?> GetApprovedRemoteAsync(Guid specialistId) =>
        (await _unitOfWork.RemoteConsultations.FindAsync(r => r.SpecialistId == specialistId && r.Status == RemoteConsultationStatus.Approved))
            .OrderBy(r => r.CreatedAt).FirstOrDefault();

    /// <summary>
    /// يُكمِل تلقائياً جلسات الكشف اون لاين المؤكدة التي انتهى وقتها (الحالة → مكتملة) ويحفظ التغيير،
    /// كي يرى الطبيب وولي الأمر حالة موحّدة "جلسة مكتملة" دون الحاجة لإنهاء يدوي.
    /// </summary>
    private async Task AutoCompleteEndedRemoteSessionsAsync(IEnumerable<Booking> bookings)
    {
        var now = WorkingHoursHelper.EgyptNow();
        var changed = 0;

        foreach (var b in bookings)
        {
            if (b.ServiceType != BookingServiceType.RemoteConsultation) continue;
            if (b.Status != BookingStatus.Confirmed) continue;
            if (!b.StartTime.HasValue) continue;

            var startLocal = b.AppointmentDate.Date + b.StartTime.Value;
            var endLocal = ComputeEndLocal(b, startLocal);
            if (now <= endLocal) continue;

            b.Status = BookingStatus.Completed;
            b.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Bookings.UpdateAsync(b);
            changed++;
        }

        if (changed > 0) await _unitOfWork.SaveChangesAsync();
    }

    private static DateTime ComputeEndLocal(Booking b, DateTime startLocal) =>
        b.EndTime.HasValue ? b.AppointmentDate.Date + b.EndTime.Value : startLocal.AddMinutes(b.DurationMinutes ?? 30);

    /// <summary>شارة الحالة لجانب الطبيب: مؤكَّد → "جاري المعالجة"، مكتمل → "جلسة مكتملة".</summary>
    private static string SessionBadgeAr(BookingStatus status) => status switch
    {
        BookingStatus.Confirmed => "جاري المعالجة",
        BookingStatus.Completed => "جلسة مكتملة",
        _ => ConsultationLabels.BookingStatusAr(status)
    };

    private DoctorSessionStatusResponse BuildSessionStatus(Booking booking)
    {
        var now = WorkingHoursHelper.EgyptNow();
        var startLocal = booking.AppointmentDate.Date + (booking.StartTime ?? TimeSpan.Zero);
        var endLocal = ComputeEndLocal(booking, startLocal);

        var sessionStarted = booking.SessionStartedAt.HasValue && !string.IsNullOrEmpty(booking.MeetingUrl);
        var sessionEnded = booking.Status == BookingStatus.Completed;

        var canStart = booking.Status == BookingStatus.Confirmed
            && !sessionStarted
            && now >= startLocal.AddMinutes(-StartLeadMinutes)
            && now <= endLocal.AddMinutes(StartGraceMinutesAfterEnd);
        var canEnd = booking.Status == BookingStatus.Confirmed && sessionStarted;

        return new DoctorSessionStatusResponse
        {
            BookingId = booking.Id,
            Status = ConsultationLabels.BookingStatusKey(booking.Status),
            StatusAr = SessionBadgeAr(booking.Status),
            AppointmentDate = booking.AppointmentDate.ToString("yyyy-MM-dd"),
            StartTime = booking.StartTime.HasValue ? WorkingHoursHelper.Format(booking.StartTime.Value) : null,
            EndTime = booking.EndTime.HasValue ? WorkingHoursHelper.Format(booking.EndTime.Value) : null,
            DurationMinutes = booking.DurationMinutes,
            ServerTimeEgypt = now,
            SecondsUntilStart = (long)Math.Round((startLocal - now).TotalSeconds),
            SecondsUntilEnd = (long)Math.Round((endLocal - now).TotalSeconds),
            SessionStarted = sessionStarted,
            SessionEnded = sessionEnded,
            CanStart = canStart,
            CanEnd = canEnd,
            JoinUrl = (sessionStarted && !sessionEnded) ? booking.MeetingUrl : null
        };
    }

    private async Task<Dictionary<Guid, string>> LoadChildNamesAsync(IEnumerable<Booking> bookings)
    {
        var childIds = bookings.Where(b => b.ChildId.HasValue).Select(b => b.ChildId!.Value).ToHashSet();
        if (childIds.Count == 0) return new Dictionary<Guid, string>();
        return (await _unitOfWork.Children.FindAsync(c => childIds.Contains(c.Id)))
            .ToDictionary(c => c.Id, c => c.FullName);
    }

    private async Task<string> ResolvePatientNameAsync(Booking booking, Dictionary<Guid, string>? childMap = null)
    {
        if (booking.ChildId.HasValue)
        {
            if (childMap != null && childMap.TryGetValue(booking.ChildId.Value, out var name)) return name;
            var child = await _unitOfWork.Children.GetByIdAsync(booking.ChildId.Value);
            return child?.FullName ?? string.Empty;
        }
        var parent = await _unitOfWork.Parents.GetByIdAsync(booking.ParentId);
        var user = parent != null ? await _unitOfWork.Users.GetByIdAsync(parent.UserId) : null;
        return user?.FullName ?? string.Empty;
    }

    private static StartSessionResponse BuildStartResponse(Booking b, string patientName) => new()
    {
        BookingId = b.Id,
        JoinUrl = b.MeetingUrl ?? string.Empty,
        SessionStartedAt = b.SessionStartedAt ?? DateTime.UtcNow,
        AppointmentDate = b.AppointmentDate.ToString("yyyy-MM-dd"),
        StartTime = b.StartTime.HasValue ? WorkingHoursHelper.Format(b.StartTime.Value) : null,
        EndTime = b.EndTime.HasValue ? WorkingHoursHelper.Format(b.EndTime.Value) : null,
        PatientName = patientName
    };
}
