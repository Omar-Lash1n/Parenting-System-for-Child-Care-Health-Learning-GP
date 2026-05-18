using Ajial.Application.DTOs.ChildTask;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Prize;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Service;

public class ChildHomeService : IChildHomeService
{
    private readonly IUnitOfWork _unitOfWork;

    public ChildHomeService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────────────────────────────────

    private static string? BuildRecurrenceSummary(ChildTaskRecurrence? recurrence)
    {
        if (recurrence == null || !recurrence.IsRecurring || string.IsNullOrWhiteSpace(recurrence.RepeatDays))
            return null;

        var arabicAbbr = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            { "saturday",  "س" }, { "friday",    "ج" }, { "thursday",  "خ" },
            { "wednesday", "أ" }, { "tuesday",   "ث" }, { "monday",    "إ" },
            { "sunday",    "ح" }
        };

        var days = recurrence.RepeatDays.Split(',', StringSplitOptions.RemoveEmptyEntries);
        var parts = days.Select(d => arabicAbbr.TryGetValue(d.Trim(), out var a) ? a : d.Trim()).ToList();
        return parts.Count == 7 ? "يومياً" : "يتكرر " + string.Join("، ", parts);
    }

    private static ChildTaskRecurrenceDto BuildRecurrenceDto(ChildTaskRecurrence? recurrence)
    {
        if (recurrence == null || !recurrence.IsRecurring)
            return new ChildTaskRecurrenceDto { IsRecurring = false };

        var days = string.IsNullOrWhiteSpace(recurrence.RepeatDays)
            ? new List<string>()
            : recurrence.RepeatDays.Split(',', StringSplitOptions.RemoveEmptyEntries)
                         .Select(d => d.Trim()).ToList();

        return new ChildTaskRecurrenceDto
        {
            IsRecurring = true,
            RepeatDays = days,
            RepeatTime = recurrence.RepeatTime
        };
    }

    private async Task<ChildTaskDetailDto> BuildDetailDtoAsync(ChildTask task)
    {
        var assigneeRows = (await _unitOfWork.ChildTaskAssignees.FindAsync(a => a.TaskId == task.Id)).ToList();
        var children = new List<AssignedChildDto>();
        foreach (var a in assigneeRows)
        {
            var child = await _unitOfWork.Children.GetByIdAsync(a.ChildId);
            if (child != null)
                children.Add(new AssignedChildDto
                {
                    ChildId = child.Id,
                    FullName = child.FullName,
                    ProfileImageUrl = child.ProfileImageUrl,
                    IsCompleted = a.IsCompleted,
                    CompletedAt = a.CompletedAt
                });
        }

        var recurrence = await _unitOfWork.ChildTaskRecurrences.GetFirstOrDefaultAsync(r => r.TaskId == task.Id);

        return new ChildTaskDetailDto
        {
            TaskId = task.Id,
            Title = task.Title,
            TaskImageUrl = task.TaskImageUrl,
            RecordingUrl = task.RecordingUrl,
            Stars = task.Stars,
            StartDate = task.StartDate,
            DueDate = task.DueDate,
            Recurrence = BuildRecurrenceDto(recurrence),
            AssignedChildren = children,
            CreatedAt = task.CreatedAt,
            UpdatedAt = task.UpdatedAt
        };
    }

    private async Task<ChildTaskCardDto> BuildCardDtoAsync(ChildTask task, Guid forChildId)
    {
        var assigneeRows = (await _unitOfWork.ChildTaskAssignees.FindAsync(a => a.TaskId == task.Id)).ToList();
        var thisChildAssignee = assigneeRows.FirstOrDefault(a => a.ChildId == forChildId);

        var children = new List<AssignedChildDto>();
        foreach (var a in assigneeRows)
        {
            var child = await _unitOfWork.Children.GetByIdAsync(a.ChildId);
            if (child != null)
                children.Add(new AssignedChildDto
                {
                    ChildId = child.Id,
                    FullName = child.FullName,
                    ProfileImageUrl = child.ProfileImageUrl,
                    IsCompleted = a.IsCompleted,
                    CompletedAt = a.CompletedAt
                });
        }

        var recurrence = await _unitOfWork.ChildTaskRecurrences.GetFirstOrDefaultAsync(r => r.TaskId == task.Id);

        return new ChildTaskCardDto
        {
            TaskId = task.Id,
            Title = task.Title,
            TaskImageUrl = task.TaskImageUrl,
            Stars = task.Stars,
            IsCompleted = thisChildAssignee?.IsCompleted ?? false,
            CompletedAt = thisChildAssignee?.CompletedAt,
            DueDate = task.DueDate,
            RecurrenceSummary = BuildRecurrenceSummary(recurrence),
            AssignedChildren = children
        };
    }

    private async Task<int> GetNetStarsAsync(Child child)
    {
        var assignees = (await _unitOfWork.ChildTaskAssignees.FindAsync(
            a => a.ChildId == child.Id && a.IsCompleted)).ToList();

        var earned = 0;
        foreach (var a in assignees)
        {
            var task = await _unitOfWork.ChildTasks.GetByIdAsync(a.TaskId);
            if (task != null) earned += task.Stars;
        }

        return Math.Max(0, earned - child.SpentStars);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PRIZE HELPERS (mirror PrizeService without parent scope check)
    // ─────────────────────────────────────────────────────────────────────────

    private async Task<int> GetChildTotalStarsAsync(Child child)
        => await GetNetStarsAsync(child);

    private async Task<PrizeCardDto> BuildPrizeCardDtoAsync(Prize prize, Child child)
    {
        var currentStars = await GetChildTotalStarsAsync(child);
        var remainingStars = Math.Max(0, prize.RequiredStars - currentStars);
        var requiredTasks = (await _unitOfWork.PrizeTasks.FindAsync(pt => pt.PrizeId == prize.Id)).ToList();
        var completedTasksCount = 0;

        foreach (var prizeTask in requiredTasks)
        {
            var assignee = await _unitOfWork.ChildTaskAssignees.GetFirstOrDefaultAsync(a =>
                a.ChildId == child.Id && a.TaskId == prizeTask.TaskId && a.IsCompleted);
            if (assignee != null) completedTasksCount++;
        }

        var allTasksDone = completedTasksCount == requiredTasks.Count;
        var effectiveStatus = prize.Status == PrizeStatus.Delivered
            ? "Delivered"
            : allTasksDone && currentStars >= prize.RequiredStars ? "Ready" : "Active";

        return new PrizeCardDto
        {
            PrizeId = prize.Id,
            Title = prize.Title,
            ImageUrl = prize.ImageUrl,
            RequiredStars = prize.RequiredStars,
            CurrentStars = currentStars,
            RemainingStars = remainingStars,
            CompletedTasksCount = completedTasksCount,
            TotalRequiredTasks = requiredTasks.Count,
            Status = effectiveStatus,
            CanDeliver = effectiveStatus == "Ready"
        };
    }

    // ─────────────────────────────────────────────────────────────────────────
    // A. GET MY TASKS
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<GetChildTasksForChildResponseDto>> GetMyTasksAsync(Guid childId)
    {
        try
        {
            var child = await _unitOfWork.Children.GetByIdAsync(childId);
            if (child == null)
                return ApiResponse<GetChildTasksForChildResponseDto>.FailureResponse("الطفل غير موجود",
                    new List<string> { "لم يتم العثور على الحساب" });

            if (!child.IsActive)
                return ApiResponse<GetChildTasksForChildResponseDto>.FailureResponse("الحساب غير نشط",
                    new List<string> { "تم إيقاف تشغيل الحساب من قِبَل ولي الأمر" });

            var assigneeRows = (await _unitOfWork.ChildTaskAssignees.FindAsync(a => a.ChildId == childId)).ToList();
            var taskIds = assigneeRows.Select(a => a.TaskId).ToHashSet();

            var allTasks = (await _unitOfWork.ChildTasks.FindAsync(ct => taskIds.Contains(ct.Id)))
                .OrderBy(t => t.DueDate)
                .ToList();

            var pending = new List<ChildTaskCardDto>();
            var completed = new List<ChildTaskCardDto>();

            foreach (var task in allTasks)
            {
                var assignee = assigneeRows.FirstOrDefault(a => a.TaskId == task.Id);
                var card = await BuildCardDtoAsync(task, childId);
                if (assignee?.IsCompleted == true) completed.Add(card);
                else pending.Add(card);
            }

            return ApiResponse<GetChildTasksForChildResponseDto>.SuccessResponse(
                new GetChildTasksForChildResponseDto
                {
                    Child = new AssignedChildDto
                    {
                        ChildId = child.Id,
                        FullName = child.FullName,
                        ProfileImageUrl = child.ProfileImageUrl
                    },
                    TotalStars = await GetNetStarsAsync(child),
                    PendingTasks = pending,
                    CompletedTasks = completed.OrderByDescending(t => t.CompletedAt).ToList()
                }, "تم جلب مهامك بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<GetChildTasksForChildResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب المهام", new List<string> { ex.Message });
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // B. GET TASK DETAILS
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<ChildTaskDetailDto>> GetMyTaskDetailsAsync(Guid taskId, Guid childId)
    {
        try
        {
            var child = await _unitOfWork.Children.GetByIdAsync(childId);
            if (child == null)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("الطفل غير موجود",
                    new List<string> { "لم يتم العثور على الحساب" });

            if (!child.IsActive)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("الحساب غير نشط",
                    new List<string> { "تم إيقاف تشغيل الحساب من قِبَل ولي الأمر" });

            var task = await _unitOfWork.ChildTasks.GetByIdAsync(taskId);
            if (task == null)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("المهمة غير موجودة",
                    new List<string> { "لم يتم العثور على المهمة" });

            var assignee = (await _unitOfWork.ChildTaskAssignees.FindAsync(
                a => a.TaskId == taskId && a.ChildId == childId)).FirstOrDefault();
            if (assignee == null)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("غير مصرح",
                    new List<string> { "هذه المهمة غير مُسندة إليك" });

            return ApiResponse<ChildTaskDetailDto>.SuccessResponse(
                await BuildDetailDtoAsync(task), "تم جلب تفاصيل المهمة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ChildTaskDetailDto>.FailureResponse(
                "حدث خطأ أثناء جلب المهمة", new List<string> { ex.Message });
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // C. MARK TASK COMPLETE (one-way — child cannot undo)
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<ChildTaskDetailDto>> MarkTaskCompleteAsync(Guid taskId, Guid childId)
    {
        try
        {
            var child = await _unitOfWork.Children.GetByIdAsync(childId);
            if (child == null)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("الطفل غير موجود",
                    new List<string> { "لم يتم العثور على الحساب" });

            if (!child.IsActive)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("الحساب غير نشط",
                    new List<string> { "تم إيقاف تشغيل الحساب من قِبَل ولي الأمر" });

            var task = await _unitOfWork.ChildTasks.GetByIdAsync(taskId);
            if (task == null)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("المهمة غير موجودة",
                    new List<string> { "لم يتم العثور على المهمة" });

            var assignee = (await _unitOfWork.ChildTaskAssignees.FindAsync(
                a => a.TaskId == taskId && a.ChildId == childId)).FirstOrDefault();
            if (assignee == null)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("غير مصرح",
                    new List<string> { "هذه المهمة غير مُسندة إليك" });

            // Idempotent: if already done, return current state without touching the DB
            if (assignee.IsCompleted)
                return ApiResponse<ChildTaskDetailDto>.SuccessResponse(
                    await BuildDetailDtoAsync(task), "المهمة مكتملة بالفعل");

            assignee.IsCompleted = true;
            assignee.CompletedAt = DateTime.Now;
            task.UpdatedAt = DateTime.Now;

            await _unitOfWork.ChildTaskAssignees.UpdateAsync(assignee);
            await _unitOfWork.ChildTasks.UpdateAsync(task);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<ChildTaskDetailDto>.SuccessResponse(
                await BuildDetailDtoAsync(task), "أحسنت! تم إنجاز المهمة");
        }
        catch (Exception ex)
        {
            return ApiResponse<ChildTaskDetailDto>.FailureResponse(
                "حدث خطأ أثناء تحديث حالة المهمة", new List<string> { ex.Message });
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // D. GET MY PRIZES
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<GetPrizesForChildResponseDto>> GetMyPrizesAsync(Guid childId)
    {
        try
        {
            var child = await _unitOfWork.Children.GetByIdAsync(childId);
            if (child == null)
                return ApiResponse<GetPrizesForChildResponseDto>.FailureResponse("الطفل غير موجود",
                    new List<string> { "لم يتم العثور على الحساب" });

            if (!child.IsActive)
                return ApiResponse<GetPrizesForChildResponseDto>.FailureResponse("الحساب غير نشط",
                    new List<string> { "تم إيقاف تشغيل الحساب من قِبَل ولي الأمر" });

            var prizes = (await _unitOfWork.Prizes.FindAsync(p => p.ChildId == childId))
                .OrderByDescending(p => p.CreatedAt)
                .ToList();

            var cards = new List<PrizeCardDto>();
            foreach (var prize in prizes)
                cards.Add(await BuildPrizeCardDtoAsync(prize, child));

            return ApiResponse<GetPrizesForChildResponseDto>.SuccessResponse(
                new GetPrizesForChildResponseDto
                {
                    ChildId = child.Id,
                    ChildFullName = child.FullName,
                    TotalStars = await GetChildTotalStarsAsync(child),
                    Prizes = cards
                }, "تم جلب الجوائز بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<GetPrizesForChildResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب الجوائز", new List<string> { ex.Message });
        }
    }
}
