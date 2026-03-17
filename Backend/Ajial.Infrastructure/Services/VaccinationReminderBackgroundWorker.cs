using Ajial.Application.Interfaces;
using Ajlal.Application.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Ajial.Infrastructure.Services;

/// <summary>
/// Background worker that runs every 60 seconds, checks the DB for due vaccination reminders,
/// and sends FCM push notifications to the parent's registered device.
///
/// Three trigger windows are checked:
///   1. 1 day before appointment (IsProcessedOneDayBefore)
///   2. 3 hours before appointment (IsProcessedThreeHoursBefore)
///   3. Custom reminder time set by parent (IsProcessedCustom)
/// </summary>
public class VaccinationReminderBackgroundWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<VaccinationReminderBackgroundWorker> _logger;

    // Check every 60 seconds
    private static readonly TimeSpan CheckInterval = TimeSpan.FromSeconds(60);

    // ±2 minute tolerance window to catch reminders that might be slightly off
    private static readonly TimeSpan ToleranceWindow = TimeSpan.FromMinutes(2);

    public VaccinationReminderBackgroundWorker(
        IServiceProvider serviceProvider,
        ILogger<VaccinationReminderBackgroundWorker> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("🔔 VaccinationReminderBackgroundWorker started.");
        System.Diagnostics.Trace.TraceInformation("\n[AZURE CONSOLE] 🔔 VaccinationReminderBackgroundWorker started!");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessDueRemindersAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in VaccinationReminderBackgroundWorker cycle.");
                System.Diagnostics.Trace.TraceError($"[AZURE CONSOLE ERROR] Background Worker crashed: {ex.Message}");
            }

            await Task.Delay(CheckInterval, stoppingToken);
        }
    }

    private async Task ProcessDueRemindersAsync()
    {
        // Use a scoped DI scope because IUnitOfWork is scoped (not singleton)
        using var scope = _serviceProvider.CreateScope();
        var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
        var fcmService = scope.ServiceProvider.GetRequiredService<IFcmService>();

        // 1. FIX: Timezone mismatch (using Local Time to match parsed frontend string)
        var now = DateTime.Now;

        _logger.LogInformation("================================================");
        _logger.LogInformation("🔍 [Reminder Worker] Cycle started at: {Now}", now);
        System.Diagnostics.Trace.TraceInformation($"[AZURE CONSOLE] 🔍 Run cycle at {now:HH:mm:ss}");

        // 2. Query Logic: Fetch ALL push-enabled appointments that have UNPROCESSED flags
        var pendingAppointments = await unitOfWork.VaccinationAppointments
            .FindAsync(va => va.IsPushEnabled && 
                (!va.IsProcessedOneDayBefore || !va.IsProcessedThreeHoursBefore || !va.IsProcessedCustom));

        var appointmentList = pendingAppointments.ToList();
        _logger.LogInformation("🔍 Found {Count} pending push-enabled appointments.", appointmentList.Count);

        foreach (var appointment in appointmentList)
        {
            _logger.LogInformation("--- Checking Appointment {AppointmentId} (ChildId: {ChildId}) ---", appointment.Id, appointment.ChildId);
            _logger.LogInformation("Appt Time (Local): {ApptTime}", appointment.AppointmentDateTime);

            // 3. Token Retrieval Verification
            var child = await unitOfWork.Children.GetByIdAsync(appointment.ChildId);
            if (child == null) continue;

            var parent = await unitOfWork.Parents.GetByIdAsync(child.ParentId);
            if (parent == null) continue;

            var parentUser = await unitOfWork.Users.GetByIdAsync(parent.UserId);
            if (parentUser == null || string.IsNullOrEmpty(parentUser.DeviceToken))
            {
                _logger.LogWarning("⚠️ No Device Token found for Parent User {UserId}", parent.UserId);
                continue;
            }

            var deviceToken = parentUser.DeviceToken;
            var childName = child.FullName;
            bool wasSaved = false;

            // ── 1-day-before reminder ──────────────────────────────────────
            if (appointment.NotifyOneDayBefore && !appointment.IsProcessedOneDayBefore)
            {
                var triggerTime = appointment.AppointmentDateTime.AddDays(-1);
                bool inWindow = IsWithinWindow(now, triggerTime);
                _logger.LogInformation("  [1 Day] Trigger: {TriggerTime} | In Window? {InWindow}", triggerTime, inWindow);
                
                if (inWindow)
                {
                    _logger.LogInformation("  📨 SENDING 1-day reminder to token {Token}", deviceToken);
                    var success = await fcmService.SendPushAsync(
                        deviceToken,
                        title: "تذكير بموعد التطعيم 💉",
                        body: $"موعد تطعيم {childName} غداً في {appointment.AppointmentDateTime:HH:mm} - {appointment.HealthUnit}",
                        data: new Dictionary<string, string>
                        {
                            { "type", "vaccination_reminder" },
                            { "childId", appointment.ChildId.ToString() },
                            { "milestoneId", appointment.VaccinationMilestoneId.ToString() }
                        });

                    if (success) _logger.LogInformation("  ✅ Successfully sent 1-day push.");
                    else _logger.LogError("  ❌ Failed to send 1-day push to FCM.");

                    appointment.IsProcessedOneDayBefore = true;
                    wasSaved = true;
                }
            }

            // ── 3-hours-before reminder ────────────────────────────────────
            if (appointment.NotifyThreeHoursBefore && !appointment.IsProcessedThreeHoursBefore)
            {
                var triggerTime = appointment.AppointmentDateTime.AddHours(-3);
                bool inWindow = IsWithinWindow(now, triggerTime);
                _logger.LogInformation("  [3 Hrs] Trigger: {TriggerTime} | In Window? {InWindow}", triggerTime, inWindow);

                if (inWindow)
                {
                    _logger.LogInformation("  📨 SENDING 3-hour reminder to token {Token}", deviceToken);
                    var success = await fcmService.SendPushAsync(
                        deviceToken,
                        title: "تذكير بموعد التطعيم 💉",
                        body: $"موعد تطعيم {childName} بعد 3 ساعات في {appointment.AppointmentDateTime:HH:mm} - {appointment.HealthUnit}",
                        data: new Dictionary<string, string>
                        {
                            { "type", "vaccination_reminder" },
                            { "childId", appointment.ChildId.ToString() },
                            { "milestoneId", appointment.VaccinationMilestoneId.ToString() }
                        });

                    if (success) _logger.LogInformation("  ✅ Successfully sent 3-hour push.");
                    else _logger.LogError("  ❌ Failed to send 3-hour push to FCM.");

                    appointment.IsProcessedThreeHoursBefore = true;
                    wasSaved = true;
                }
            }

            // ── Custom reminder ────────────────────────────────────────────
            if (appointment.CustomReminderEnabled &&
                !appointment.IsProcessedCustom &&
                appointment.CustomReminderDateTime.HasValue)
            {
                var triggerTime = appointment.CustomReminderDateTime.Value;
                bool inWindow = IsWithinWindow(now, triggerTime);
                _logger.LogInformation("  [Custom] Trigger: {TriggerTime} | In Window? {InWindow}", triggerTime, inWindow);

                if (inWindow)
                {
                    _logger.LogInformation("  📨 SENDING Custom reminder to token {Token}", deviceToken);
                    var success = await fcmService.SendPushAsync(
                        deviceToken,
                        title: "تذكير بموعد التطعيم 💉",
                        body: $"تذكير: موعد تطعيم {childName} في {appointment.AppointmentDateTime:yyyy-MM-dd HH:mm} - {appointment.HealthUnit}",
                        data: new Dictionary<string, string>
                        {
                            { "type", "vaccination_reminder" },
                            { "childId", appointment.ChildId.ToString() },
                            { "milestoneId", appointment.VaccinationMilestoneId.ToString() }
                        });

                    if (success) _logger.LogInformation("  ✅ Successfully sent Custom push.");
                    else _logger.LogError("  ❌ Failed to send Custom push to FCM.");

                    appointment.IsProcessedCustom = true;
                    wasSaved = true;
                }
            }

            // Persist flag changes only if we actually sent something
            if (wasSaved)
            {
                await unitOfWork.VaccinationAppointments.UpdateAsync(appointment);
                await unitOfWork.SaveChangesAsync();
                _logger.LogInformation("  💾 Saved processed flags to DB.");
            }
        }
    }

    /// <summary>
    /// Returns true if 'now' falls within [triggerTime - tolerance, triggerTime + tolerance].
    /// This prevents missed notifications caused by the 60-second polling interval.
    /// </summary>
    private static bool IsWithinWindow(DateTime now, DateTime triggerTime)
    {
        return now >= triggerTime - ToleranceWindow &&
               now <= triggerTime + ToleranceWindow;
    }
}
