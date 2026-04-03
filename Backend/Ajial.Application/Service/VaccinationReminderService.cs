using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.VaccinationReminder;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace Ajial.Application.Services;

/// <summary>
/// Business logic for the "تفاصيل الموعد" vaccination reminder page.
/// Handles save, update/reset, device token registration, and reminder lookup.
/// </summary>
public class VaccinationReminderService : IVaccinationReminderService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<VaccinationReminderService> _logger;

    public VaccinationReminderService(
        IUnitOfWork unitOfWork,
        ILogger<VaccinationReminderService> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GET: return existing reminder config for a child + milestone
    // ─────────────────────────────────────────────────────────────────────────
    public async Task<ApiResponse<ReminderDto?>> GetReminderAsync(
        Guid childId, int milestoneId, Guid requestingUserId)
    {
        try
        {
            // Security: verify the child belongs to the calling parent
            var child = await _unitOfWork.Children.GetByIdAsync(childId);
            if (child == null)
                return ApiResponse<ReminderDto?>.FailureResponse("الطفل غير موجود");

            var parent = await _unitOfWork.Parents
                .GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);

            if (parent == null || child.ParentId != parent.Id)
                return ApiResponse<ReminderDto?>.FailureResponse("غير مصرح لك بالوصول لبيانات هذا الطفل");

            // Fetch the appointment record if it exists
            var appointment = await _unitOfWork.VaccinationAppointments
                .GetFirstOrDefaultAsync(va =>
                    va.ChildId == childId &&
                    va.VaccinationMilestoneId == milestoneId);

            if (appointment == null)
            {
                // No appointment saved yet — return success with null data
                return ApiResponse<ReminderDto?>.SuccessResponse(null, "لم يتم تعيين موعد بعد");
            }

            return ApiResponse<ReminderDto?>.SuccessResponse(MapToDto(appointment));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching vaccination reminder for child {ChildId}", childId);
            return ApiResponse<ReminderDto?>.FailureResponse("حدث خطأ أثناء جلب بيانات الموعد");
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // POST: create or update reminder (وضع تذكير / إعادة ضبط الموعد)
    // ─────────────────────────────────────────────────────────────────────────
    public async Task<ApiResponse<ReminderDto>> UpsertReminderAsync(
        SaveReminderRequest request, Guid requestingUserId)
    {
        try
        {
            // ── Validate ownership ─────────────────────────────────────────
            var child = await _unitOfWork.Children.GetByIdAsync(request.ChildId);
            if (child == null)
                return ApiResponse<ReminderDto>.FailureResponse("الطفل غير موجود");

            var parent = await _unitOfWork.Parents
                .GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);

            if (parent == null || child.ParentId != parent.Id)
                return ApiResponse<ReminderDto>.FailureResponse("غير مصرح لك بالوصول لبيانات هذا الطفل");

            // ── Validate milestone exists ──────────────────────────────────
            var milestone = await _unitOfWork.VaccinationMilestones.GetByIdAsync(request.MilestoneId);
            if (milestone == null)
                return ApiResponse<ReminderDto>.FailureResponse("جرعة التطعيم غير موجودة");

            // ── Parse appointment date + time ──────────────────────────────
            if (!DateTime.TryParse($"{request.AppointmentDate} {request.AppointmentTime}",
                out var appointmentDateTime))
            {
                return ApiResponse<ReminderDto>.FailureResponse(
                    "تنسيق التاريخ أو الوقت غير صحيح",
                    new List<string> { "يجب أن يكون التاريخ بصيغة yyyy-MM-dd والوقت HH:mm" });
            }

            if (appointmentDateTime <= DateTime.Now)
            {
                return ApiResponse<ReminderDto>.FailureResponse(
                    "موعد غير صالح",
                    new List<string> { "يجب أن يكون موعد التطعيم في المستقبل" });
            }

            // ── Parse custom reminder time ─────────────────────────────────
            DateTime? customReminderDateTime = null;
            if (request.CustomReminderEnabled)
            {
                if (string.IsNullOrEmpty(request.CustomReminderDateTime))
                {
                    return ApiResponse<ReminderDto>.FailureResponse(
                        "وقت التذكير المخصص مطلوب",
                        new List<string> { "يرجى تحديد وقت التذكير المخصص" });
                }

                if (!DateTime.TryParse(request.CustomReminderDateTime, out var parsedCustom))
                {
                    return ApiResponse<ReminderDto>.FailureResponse(
                        "تنسيق وقت التذكير المخصص غير صحيح");
                }

                if (parsedCustom >= appointmentDateTime)
                {
                    return ApiResponse<ReminderDto>.FailureResponse(
                        "وقت التذكير المخصص غير صالح",
                        new List<string> { "يجب أن يكون وقت التذكير قبل موعد التطعيم" });
                }

                customReminderDateTime = parsedCustom;
            }

            // ── Upsert logic ───────────────────────────────────────────────
            var existing = await _unitOfWork.VaccinationAppointments
                .GetFirstOrDefaultAsync(va =>
                    va.ChildId == request.ChildId &&
                    va.VaccinationMilestoneId == request.MilestoneId);

            var now = DateTime.Now;

            if (existing == null)
            {
                // CREATE new appointment record
                var newAppointment = new VaccinationAppointment
                {
                    Id = Guid.NewGuid(),
                    ChildId = request.ChildId,
                    VaccinationMilestoneId = request.MilestoneId,
                    HealthUnit = request.HealthUnit,
                    AppointmentDateTime = appointmentDateTime,
                    NotifyOneDayBefore = request.NotifyOneDayBefore,
                    NotifyThreeHoursBefore = request.NotifyThreeHoursBefore,
                    CustomReminderEnabled = request.CustomReminderEnabled,
                    CustomReminderDateTime = customReminderDateTime,
                    IsAlarmEnabled = request.IsAlarmEnabled,
                    IsPushEnabled = request.IsPushEnabled,
                    // Processing flags all start as false on creation
                    IsProcessedOneDayBefore = false,
                    IsProcessedThreeHoursBefore = false,
                    IsProcessedCustom = false,
                    IsProcessedAtTime = false,
                    CreatedAt = now,
                    UpdatedAt = now
                };

                await _unitOfWork.VaccinationAppointments.AddAsync(newAppointment);
                await _unitOfWork.SaveChangesAsync();

                _logger.LogInformation(
                    "✅ Created vaccination reminder for child {ChildId}, milestone {MilestoneId}",
                    request.ChildId, request.MilestoneId);

                return ApiResponse<ReminderDto>.SuccessResponse(
                    MapToDto(newAppointment), "تم حفظ التذكير بنجاح");
            }
            else
            {
                // UPDATE / RESET existing appointment record
                // Reset all processing flags so reminders fire again for the new appointment
                existing.HealthUnit = request.HealthUnit;
                existing.AppointmentDateTime = appointmentDateTime;
                existing.NotifyOneDayBefore = request.NotifyOneDayBefore;
                existing.NotifyThreeHoursBefore = request.NotifyThreeHoursBefore;
                existing.CustomReminderEnabled = request.CustomReminderEnabled;
                existing.CustomReminderDateTime = customReminderDateTime;
                existing.IsAlarmEnabled = request.IsAlarmEnabled;
                existing.IsPushEnabled = request.IsPushEnabled;
                // ⚠️ Critical: reset flags so background worker sends again
                existing.IsProcessedOneDayBefore = false;
                existing.IsProcessedThreeHoursBefore = false;
                existing.IsProcessedCustom = false;
                existing.IsProcessedAtTime = false;
                existing.UpdatedAt = now;

                await _unitOfWork.VaccinationAppointments.UpdateAsync(existing);
                await _unitOfWork.SaveChangesAsync();

                _logger.LogInformation(
                    "✅ Reset vaccination reminder for child {ChildId}, milestone {MilestoneId}",
                    request.ChildId, request.MilestoneId);

                return ApiResponse<ReminderDto>.SuccessResponse(
                    MapToDto(existing), "تم إعادة ضبط التذكير بنجاح");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error upserting vaccination reminder");
            return ApiResponse<ReminderDto>.FailureResponse(
                "حدث خطأ أثناء حفظ التذكير",
                new List<string> { "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى" });
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Register/update device token for FCM push notifications
    // ─────────────────────────────────────────────────────────────────────────
    public async Task<ApiResponse<bool>> RegisterDeviceTokenAsync(string deviceToken, Guid userId)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(deviceToken))
                return ApiResponse<bool>.FailureResponse("رمز الجهاز لا يمكن أن يكون فارغاً");

            var user = await _unitOfWork.Users.GetByIdAsync(userId);
            if (user == null)
                return ApiResponse<bool>.FailureResponse("المستخدم غير موجود");

            user.DeviceToken = deviceToken;
            await _unitOfWork.Users.UpdateAsync(user);
            await _unitOfWork.SaveChangesAsync();

            _logger.LogInformation("✅ Device token registered for user {UserId}", userId);
            return ApiResponse<bool>.SuccessResponse(true, "تم تسجيل رمز الجهاز بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error registering device token for user {UserId}", userId);
            return ApiResponse<bool>.FailureResponse("حدث خطأ أثناء تسجيل رمز الجهاز");
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helper: map entity to DTO
    // ─────────────────────────────────────────────────────────────────────────
    private static ReminderDto MapToDto(VaccinationAppointment va) => new()
    {
        Id = va.Id,
        ChildId = va.ChildId,
        MilestoneId = va.VaccinationMilestoneId,
        HealthUnit = va.HealthUnit,
        AppointmentDate = va.AppointmentDateTime.ToString("yyyy-MM-dd"),
        AppointmentTime = va.AppointmentDateTime.ToString("HH:mm"),
        NotifyOneDayBefore = va.NotifyOneDayBefore,
        NotifyThreeHoursBefore = va.NotifyThreeHoursBefore,
        CustomReminderEnabled = va.CustomReminderEnabled,
        CustomReminderDateTime = va.CustomReminderDateTime?.ToString("yyyy-MM-ddTHH:mm"),
        IsAlarmEnabled = va.IsAlarmEnabled,
        IsPushEnabled = va.IsPushEnabled,
        CreatedAt = va.CreatedAt,
        UpdatedAt = va.UpdatedAt
    };
}
