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

    public DoctorConsultationService(IUnitOfWork unitOfWork, IMeetingService meetingService)
    {
        _unitOfWork = unitOfWork;
        _meetingService = meetingService;
    }

    public async Task<ApiResponse<StartSessionResponse>> StartSessionAsync(Guid userId, Guid bookingId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.UserId == userId);
            if (specialist == null)
                return ApiResponse<StartSessionResponse>.FailureResponse("لم يتم العثور على بيانات الطبيب");

            var booking = await _unitOfWork.Bookings.GetByIdAsync(bookingId);
            if (booking == null)
                return ApiResponse<StartSessionResponse>.FailureResponse("لم يتم العثور على الحجز");
            if (booking.SpecialistId != specialist.Id)
                return ApiResponse<StartSessionResponse>.FailureResponse("غير مصرح - هذا الحجز لا يخصك");

            if (booking.ServiceType != BookingServiceType.RemoteConsultation)
                return ApiResponse<StartSessionResponse>.FailureResponse("هذا الحجز ليس جلسة اون لاين");
            if (booking.Status != BookingStatus.Confirmed)
                return ApiResponse<StartSessionResponse>.FailureResponse("لا يمكن بدء الجلسة في الحالة الحالية للحجز");
            if (!booking.StartTime.HasValue)
                return ApiResponse<StartSessionResponse>.FailureResponse("بيانات موعد الجلسة غير مكتملة");

            var patientName = await ResolvePatientNameAsync(booking);

            // idempotent: إذا بدأت الجلسة مسبقاً أعِد نفس الرابط دون إنشاء اجتماع جديد
            if (booking.SessionStartedAt.HasValue && !string.IsNullOrEmpty(booking.MeetingUrl))
                return ApiResponse<StartSessionResponse>.SuccessResponse(
                    BuildResponse(booking, patientName), "الجلسة بدأت بالفعل");

            // التحقق من النافذة الزمنية (لا يمكن البدء قبل الموعد بأكثر من 5 دقائق)
            var now = WorkingHoursHelper.EgyptNow();
            var startLocal = booking.AppointmentDate.Date + booking.StartTime.Value;
            var endLocal = booking.EndTime.HasValue
                ? booking.AppointmentDate.Date + booking.EndTime.Value
                : startLocal.AddMinutes(booking.DurationMinutes ?? 30);

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
                BuildResponse(booking, patientName), "تم بدء الجلسة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<StartSessionResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    private async Task<string> ResolvePatientNameAsync(Booking booking)
    {
        if (booking.ChildId.HasValue)
        {
            var child = await _unitOfWork.Children.GetByIdAsync(booking.ChildId.Value);
            return child?.FullName ?? string.Empty;
        }
        var parent = await _unitOfWork.Parents.GetByIdAsync(booking.ParentId);
        var user = parent != null ? await _unitOfWork.Users.GetByIdAsync(parent.UserId) : null;
        return user?.FullName ?? string.Empty;
    }

    private static StartSessionResponse BuildResponse(Booking b, string patientName) => new()
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
