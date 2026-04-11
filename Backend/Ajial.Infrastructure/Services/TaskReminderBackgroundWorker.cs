using Ajial.Application.Interfaces;
using Ajlal.Application.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Ajial.Infrastructure.Services;

/// <summary>
/// Background worker that runs every 60 seconds, checks the DB for tasks with a due date,
/// and sends an FCM push notification to the parent's registered device at the due time.
///
/// IsPushSent = false  → task is eligible for notification (user explicitly set a due date)
/// IsPushSent = true   → notification already sent or task used today-default (no notification needed)
/// </summary>
public class TaskReminderBackgroundWorker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<TaskReminderBackgroundWorker> _logger;

    private static readonly TimeSpan CheckInterval = TimeSpan.FromSeconds(60);

    // ±2 minute tolerance window — same as VaccinationReminderBackgroundWorker
    private static readonly TimeSpan ToleranceWindow = TimeSpan.FromMinutes(2);

    public TaskReminderBackgroundWorker(
        IServiceProvider serviceProvider,
        ILogger<TaskReminderBackgroundWorker> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("🔔 TaskReminderBackgroundWorker started.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessDueTaskRemindersAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in TaskReminderBackgroundWorker cycle.");
            }

            await Task.Delay(CheckInterval, stoppingToken);
        }
    }

    private async Task ProcessDueTaskRemindersAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var unitOfWork = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
        var fcmService = scope.ServiceProvider.GetRequiredService<IFcmService>();

        var now = DateTime.Now;

        _logger.LogInformation("🔍 [TaskReminder] Cycle at: {Now}", now);

        // Query tasks that need a notification and are due within the tolerance window
        var dueTasks = await unitOfWork.Tasks.FindAsync(
            t => !t.IsPushSent &&
                 t.DueDate.HasValue &&
                 t.DueDate.Value >= now - ToleranceWindow &&
                 t.DueDate.Value <= now + ToleranceWindow
        );

        var taskList = dueTasks.ToList();
        _logger.LogInformation("🔍 Found {Count} due task reminders.", taskList.Count);

        foreach (var task in taskList)
        {
            _logger.LogInformation("--- Checking Task {TaskId} (ParentId: {ParentId}) DueDate: {DueDate} ---",
                task.Id, task.ParentId, task.DueDate);

            // Get parent → user → device token
            var parent = await unitOfWork.Parents.GetByIdAsync(task.ParentId);
            if (parent == null)
            {
                _logger.LogWarning("⚠️ Parent not found for task {TaskId}", task.Id);
                continue;
            }

            var parentUser = await unitOfWork.Users.GetByIdAsync(parent.UserId);
            if (parentUser == null || string.IsNullOrEmpty(parentUser.DeviceToken))
            {
                _logger.LogWarning("⚠️ No Device Token found for Parent User {UserId}", parent.UserId);
                // Mark as sent to avoid retrying on every cycle
                task.IsPushSent = true;
                await unitOfWork.Tasks.UpdateAsync(task);
                await unitOfWork.SaveChangesAsync();
                continue;
            }

            var success = await fcmService.SendPushAsync(
                parentUser.DeviceToken,
                title: "تذكير بمهمة 📋",
                body: task.Title,
                data: new Dictionary<string, string>
                {
                    { "type", "task_reminder" },
                    { "taskId", task.Id.ToString() }
                });

            if (success)
                _logger.LogInformation("  ✅ Sent task reminder for task {TaskId}", task.Id);
            else
                _logger.LogError("  ❌ Failed to send task reminder for task {TaskId}", task.Id);

            // Mark as sent regardless of FCM result to prevent infinite retries
            task.IsPushSent = true;
            await unitOfWork.Tasks.UpdateAsync(task);
            await unitOfWork.SaveChangesAsync();
        }
    }
}
