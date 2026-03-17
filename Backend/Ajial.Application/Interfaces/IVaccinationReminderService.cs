using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.VaccinationReminder;

namespace Ajial.Application.Interfaces;

public interface IVaccinationReminderService
{
    /// <summary>
    /// Returns the saved reminder settings for a specific child + vaccination milestone.
    /// Called when the parent opens the "تفاصيل الموعد" page.
    /// Returns null inside ApiResponse.Data if no appointment has been set yet.
    /// </summary>
    Task<ApiResponse<ReminderDto?>> GetReminderAsync(Guid childId, int milestoneId, Guid requestingUserId);

    /// <summary>
    /// Creates or updates (upserts) the appointment and reminder configuration.
    /// Resets all IsProcessed flags so future reminders fire again after a reset.
    /// Called when the parent taps "وضع تذكير" or "إعادة ضبط الموعد".
    /// </summary>
    Task<ApiResponse<ReminderDto>> UpsertReminderAsync(SaveReminderRequest request, Guid requestingUserId);

    /// <summary>
    /// Saves or updates the FCM device token for the currently logged-in user.
    /// Called by Flutter after app launch and after each login.
    /// </summary>
    Task<ApiResponse<bool>> RegisterDeviceTokenAsync(string deviceToken, Guid userId);
}
