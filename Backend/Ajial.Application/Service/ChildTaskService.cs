using Ajial.Application.DTOs.ChildTask;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Service;

public class ChildTaskService : IChildTaskService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IImageService _imageService;

    public ChildTaskService(IUnitOfWork unitOfWork, IImageService imageService)
    {
        _unitOfWork = unitOfWork;
        _imageService = imageService;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // HELPERS
    // ─────────────────────────────────────────────────────────────────────────

    private static int ComputeAgeYears(DateTime birthDate)
    {
        var today = DateTime.Today;
        var age = today.Year - birthDate.Year;
        if (birthDate.Date > today.AddYears(-age)) age--;
        return age;
    }

    private static int ComputeAgeMonths(DateTime birthDate)
    {
        var today = DateTime.Today;
        var months = (today.Year - birthDate.Year) * 12 + (today.Month - birthDate.Month);
        if (today.Day < birthDate.Day) months--;
        return Math.Max(0, months % 12);
    }

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
        if (parts.Count == 7) return "يومياً";
        return "يتكرر " + string.Join("، ", parts);
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

    // ─────────────────────────────────────────────────────────────────────────
    // A. GET Children For Tasks Page
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<GetChildrenForTasksResponseDto>> GetChildrenForTasksAsync(
        Guid parentId, Guid requestingUserId)
    {
        try
        {
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null || parent.Id != parentId)
                return ApiResponse<GetChildrenForTasksResponseDto>.FailureResponse("غير مصرح",
                    new List<string> { "لا يمكنك الوصول إلى بيانات هذا المستخدم" });

            var children = (await _unitOfWork.Children.FindAsync(c => c.ParentId == parentId)).ToList();
            var allTasks = (await _unitOfWork.ChildTasks.FindAsync(ct => ct.ParentId == parentId)).ToList();
            var allAssignees = new List<ChildTaskAssignee>();
            foreach (var task in allTasks)
                allAssignees.AddRange(await _unitOfWork.ChildTaskAssignees.FindAsync(a => a.TaskId == task.Id));

            var dtos = new List<ChildForTasksDto>();
            foreach (var child in children)
            {
                var ageYears = ComputeAgeYears(child.BirthDate);
                var ageMonths = ComputeAgeMonths(child.BirthDate);
                var locked = ageYears < 4;
                // HasAccount is true only when the child has BOTH a ChildLoginId AND a PasswordHash,
                // meaning the child has actually registered their account from the child-side app.
                // ChildLoginId alone can be set by the parent at child creation without the child
                // ever logging in, so PasswordHash is the definitive indicator of a real child account.
                var hasAccount = !string.IsNullOrEmpty(child.ChildLoginId) && !string.IsNullOrEmpty(child.PasswordHash);
                var isActive = child.IsActive;

                string childStatus; string? lockedReason = null;
                if (locked)           { childStatus = "locked_by_age"; lockedReason = "الميزة تفتح عند إتمام الطفل 4 سنوات"; }
                else if (!hasAccount) childStatus = "no_account";
                else if (!isActive)   childStatus = "account_inactive";
                else                  childStatus = "eligible";

                var childAssignees = allAssignees.Where(a => a.ChildId == child.Id).ToList();
                var childTaskIds = childAssignees.Select(a => a.TaskId).ToHashSet();
                var childTasks = allTasks.Where(t => childTaskIds.Contains(t.Id)).ToList();

                dtos.Add(new ChildForTasksDto
                {
                    ChildId = child.Id, FullName = child.FullName, ProfileImageUrl = child.ProfileImageUrl,
                    BirthDate = child.BirthDate, AgeYears = ageYears, AgeMonths = ageMonths, Gender = child.Gender,
                    ChildTasksLocked = locked, LockedReason = lockedReason, HasAccount = hasAccount,
                    IsAccountActive = isActive, ChildStatus = childStatus,
                    // Stars = sum of Stars for tasks completed by THIS child
                    TotalStars = childAssignees.Where(a => a.IsCompleted)
                                               .Join(allTasks, a => a.TaskId, t => t.Id, (a, t) => t.Stars)
                                               .Sum(),
                    PendingTasksCount = childAssignees.Count(a => !a.IsCompleted)
                });
            }

            return ApiResponse<GetChildrenForTasksResponseDto>.SuccessResponse(
                new GetChildrenForTasksResponseDto { Children = dtos }, "تم جلب قائمة الأطفال بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<GetChildrenForTasksResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب قائمة الأطفال", new List<string> { ex.Message });
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // B. CREATE Child Task
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<ChildTaskDetailDto>> CreateChildTaskAsync(
        CreateChildTaskRequestDto request, Guid requestingUserId)
    {
        try
        {
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("غير مصرح",
                    new List<string> { "لم يتم العثور على ولي الأمر" });

            if (request.SelectedChildIds == null || request.SelectedChildIds.Count == 0)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("بيانات غير صحيحة",
                    new List<string> { "يجب اختيار طفل واحد على الأقل" });

            foreach (var childId in request.SelectedChildIds)
            {
                var child = await _unitOfWork.Children.GetByIdAsync(childId);
                if (child == null || child.ParentId != parent.Id)
                    return ApiResponse<ChildTaskDetailDto>.FailureResponse("طفل غير موجود",
                        new List<string> { "الطفل المحدد غير موجود ضمن أطفالك" });
                if (ComputeAgeYears(child.BirthDate) < 4)
                    return ApiResponse<ChildTaskDetailDto>.FailureResponse("غير مسموح",
                        new List<string> { $"لا يمكن إسناد مهام للطفل '{child.FullName}' — الميزة تفتح عند إتمام الطفل 4 سنوات" });
            }

            // Upload task image (optional)
            string? taskImageUrl = null;
            if (request.TaskImage != null && request.TaskImage.Length > 0)
            {
                try   { taskImageUrl = await _imageService.UploadChildTaskImageAsync(request.TaskImage, requestingUserId); }
                catch (ArgumentException ex) { return ApiResponse<ChildTaskDetailDto>.FailureResponse("خطأ في ملف الصورة", new List<string> { ex.Message }); }
            }

            // Upload recording (optional)
            string? recordingUrl = null;
            if (request.Recording != null && request.Recording.Length > 0)
            {
                try   { recordingUrl = await _imageService.UploadChildTaskRecordingAsync(request.Recording, requestingUserId); }
                catch (ArgumentException ex) { return ApiResponse<ChildTaskDetailDto>.FailureResponse("خطأ في ملف التسجيل", new List<string> { ex.Message }); }
            }

            var task = new ChildTask
            {
                Id = Guid.NewGuid(),
                ParentId = parent.Id,
                Title = request.Title.Trim(),
                TaskImageUrl = taskImageUrl,
                RecordingUrl = recordingUrl,
                Stars = request.Stars,
                StartDate = request.StartDate,
                DueDate = request.DueDate,
                CreatedAt = DateTime.Now
            };

            await _unitOfWork.ChildTasks.AddAsync(task);

            foreach (var childId in request.SelectedChildIds)
                await _unitOfWork.ChildTaskAssignees.AddAsync(new ChildTaskAssignee
                {
                    TaskId = task.Id,
                    ChildId = childId,
                    IsCompleted = false,
                    CompletedAt = null
                });

            if (request.IsRecurring && !string.IsNullOrWhiteSpace(request.RepeatDays))
            {
                await _unitOfWork.ChildTaskRecurrences.AddAsync(new ChildTaskRecurrence
                {
                    Id = Guid.NewGuid(),
                    TaskId = task.Id,
                    IsRecurring = true,
                    RepeatDays = request.RepeatDays.ToLowerInvariant().Trim(),
                    RepeatTime = request.RepeatTime
                });
            }

            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<ChildTaskDetailDto>.SuccessResponse(
                await BuildDetailDtoAsync(task), "تم إضافة المهمة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ChildTaskDetailDto>.FailureResponse(
                "حدث خطأ أثناء إضافة المهمة", new List<string> { ex.Message });
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // C. GET Tasks By Child
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<GetChildTasksForChildResponseDto>> GetChildTasksByChildAsync(
        Guid childId, Guid requestingUserId)
    {
        try
        {
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null)
                return ApiResponse<GetChildTasksForChildResponseDto>.FailureResponse("غير مصرح",
                    new List<string> { "لم يتم العثور على ولي الأمر" });

            var child = await _unitOfWork.Children.GetByIdAsync(childId);
            if (child == null || child.ParentId != parent.Id)
                return ApiResponse<GetChildTasksForChildResponseDto>.FailureResponse("الطفل غير موجود",
                    new List<string> { "لم يتم العثور على الطفل" });

            var assigneeRows = (await _unitOfWork.ChildTaskAssignees.FindAsync(a => a.ChildId == childId)).ToList();
            var taskIds = assigneeRows.Select(a => a.TaskId).ToHashSet();
            var allTasks = (await _unitOfWork.ChildTasks.FindAsync(
                ct => ct.ParentId == parent.Id && taskIds.Contains(ct.Id))).ToList();

            var pending = new List<ChildTaskCardDto>();
            var completed = new List<ChildTaskCardDto>();

            foreach (var task in allTasks.OrderBy(t => t.DueDate))
            {
                var assignee = assigneeRows.FirstOrDefault(a => a.TaskId == task.Id);
                var card = await BuildCardDtoAsync(task, childId);
                if (assignee?.IsCompleted == true) completed.Add(card);
                else pending.Add(card);
            }

            // Total stars = sum of Stars for tasks THIS child has specifically completed
            var totalStars = assigneeRows
                .Where(a => a.IsCompleted)
                .Join(allTasks, a => a.TaskId, t => t.Id, (a, t) => t.Stars)
                .Sum();

            return ApiResponse<GetChildTasksForChildResponseDto>.SuccessResponse(
                new GetChildTasksForChildResponseDto
                {
                    Child = new AssignedChildDto { ChildId = child.Id, FullName = child.FullName, ProfileImageUrl = child.ProfileImageUrl },
                    TotalStars = totalStars,
                    PendingTasks = pending,
                    CompletedTasks = completed.OrderByDescending(t => t.CompletedAt).ToList()
                }, "تم جلب مهام الطفل بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<GetChildTasksForChildResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب مهام الطفل", new List<string> { ex.Message });
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // D. GET Task By ID
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<ChildTaskDetailDto>> GetChildTaskByIdAsync(Guid taskId, Guid childId, Guid requestingUserId)
    {
        try
        {
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("غير مصرح",
                    new List<string> { "لم يتم العثور على ولي الأمر" });

            var task = await _unitOfWork.ChildTasks.GetByIdAsync(taskId);
            if (task == null || task.ParentId != parent.Id)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("المهمة غير موجودة",
                    new List<string> { "لم يتم العثور على المهمة" });

            // Verify the child is assigned to this task
            var assignee = (await _unitOfWork.ChildTaskAssignees.FindAsync(
                a => a.TaskId == taskId && a.ChildId == childId)).FirstOrDefault();
            if (assignee == null)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("الطفل غير مرتبط بهذه المهمة",
                    new List<string> { "هذا الطفل ليس من المحددين في هذه المهمة" });

            return ApiResponse<ChildTaskDetailDto>.SuccessResponse(
                await BuildDetailDtoAsync(task), "تم جلب تفاصيل المهمة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ChildTaskDetailDto>.FailureResponse(
                "حدث خطأ أثناء جلب تفاصيل المهمة", new List<string> { ex.Message });
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // E. UPDATE Child Task (full partial update)
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<ChildTaskDetailDto>> UpdateChildTaskAsync(
        Guid taskId, Guid childId, UpdateChildTaskRequestDto request, Guid requestingUserId)
    {
        try
        {
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("غير مصرح",
                    new List<string> { "لم يتم العثور على ولي الأمر" });

            var task = await _unitOfWork.ChildTasks.GetByIdAsync(taskId);
            if (task == null || task.ParentId != parent.Id)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("المهمة غير موجودة",
                    new List<string> { "لم يتم العثور على المهمة" });

            // Verify this child is assigned to the task
            var callerAssignee = (await _unitOfWork.ChildTaskAssignees.FindAsync(
                a => a.TaskId == taskId && a.ChildId == childId)).FirstOrDefault();
            if (callerAssignee == null)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("الطفل غير مرتبط بهذه المهمة",
                    new List<string> { "هذا الطفل ليس من المحددين في هذه المهمة" });

            // ── Parse string fields (empty = keep current) ────────────────────
            int? parsedStars = null;
            if (!string.IsNullOrWhiteSpace(request.Stars) && int.TryParse(request.Stars, out var sv)) parsedStars = sv;

            DateTime? parsedStartDate = null; bool startDateProvided = false;
            if (!string.IsNullOrWhiteSpace(request.StartDate))
            { startDateProvided = true; if (DateTime.TryParse(request.StartDate, out var sd)) parsedStartDate = sd; }

            DateTime? parsedDueDate = null; bool dueDateProvided = false;
            if (!string.IsNullOrWhiteSpace(request.DueDate))
            { dueDateProvided = true; if (DateTime.TryParse(request.DueDate, out var dd)) parsedDueDate = dd; }

            bool? parsedIsRecurring = null;
            if (!string.IsNullOrWhiteSpace(request.IsRecurring) && bool.TryParse(request.IsRecurring, out var ir)) parsedIsRecurring = ir;

            // SelectedChildIds — parse valid Guids only, skip empty entries
            var newChildIds = request.SelectedChildIds?
                .Where(s => !string.IsNullOrWhiteSpace(s) && Guid.TryParse(s, out _))
                .Select(s => Guid.Parse(s))
                .ToList();

            // ── Update assignees only if a valid non-empty list was sent ───────
            if (newChildIds != null && newChildIds.Count > 0)
            {
                foreach (var newChildId in newChildIds)
                {
                    var child = await _unitOfWork.Children.GetByIdAsync(newChildId);
                    if (child == null || child.ParentId != parent.Id)
                        return ApiResponse<ChildTaskDetailDto>.FailureResponse("طفل غير موجود",
                            new List<string> { "الطفل المحدد غير موجود ضمن أطفالك" });
                    if (ComputeAgeYears(child.BirthDate) < 4)
                        return ApiResponse<ChildTaskDetailDto>.FailureResponse("غير مسموح",
                            new List<string> { $"لا يمكن إسناد مهام للطفل '{child.FullName}' — الميزة تفتح عند إتمام الطفل 4 سنوات" });
                }

                var existingAssignees = (await _unitOfWork.ChildTaskAssignees.FindAsync(a => a.TaskId == taskId)).ToList();
                foreach (var a in existingAssignees) await _unitOfWork.ChildTaskAssignees.DeleteAsync(a);
                foreach (var newChildId in newChildIds)
                    await _unitOfWork.ChildTaskAssignees.AddAsync(new ChildTaskAssignee
                    {
                        TaskId = task.Id,
                        ChildId = newChildId,
                        IsCompleted = false,
                        CompletedAt = null
                    });
            }

            // ── Task Image ────────────────────────────────────────────────────
            string? finalTaskImageUrl = task.TaskImageUrl;
            if (request.TaskImage != null && request.TaskImage.Length > 0)
            {
                if (!string.IsNullOrEmpty(task.TaskImageUrl)) await _imageService.DeleteBlobByUrlAsync(task.TaskImageUrl);
                try   { finalTaskImageUrl = await _imageService.UploadChildTaskImageAsync(request.TaskImage, requestingUserId); }
                catch (ArgumentException ex) { return ApiResponse<ChildTaskDetailDto>.FailureResponse("خطأ في ملف الصورة", new List<string> { ex.Message }); }
            }
            else if (request.ExistingTaskImageUrl != null)
            {
                if (string.IsNullOrEmpty(request.ExistingTaskImageUrl))
                { if (!string.IsNullOrEmpty(task.TaskImageUrl)) await _imageService.DeleteBlobByUrlAsync(task.TaskImageUrl); finalTaskImageUrl = null; }
                else finalTaskImageUrl = request.ExistingTaskImageUrl;
            }

            // ── Recording ─────────────────────────────────────────────────────
            string? finalRecordingUrl = task.RecordingUrl;
            if (request.Recording != null && request.Recording.Length > 0)
            {
                if (!string.IsNullOrEmpty(task.RecordingUrl)) await _imageService.DeleteBlobByUrlAsync(task.RecordingUrl);
                try   { finalRecordingUrl = await _imageService.UploadChildTaskRecordingAsync(request.Recording, requestingUserId); }
                catch (ArgumentException ex) { return ApiResponse<ChildTaskDetailDto>.FailureResponse("خطأ في ملف التسجيل", new List<string> { ex.Message }); }
            }
            else if (request.ExistingRecordingUrl != null)
            {
                if (string.IsNullOrEmpty(request.ExistingRecordingUrl))
                { if (!string.IsNullOrEmpty(task.RecordingUrl)) await _imageService.DeleteBlobByUrlAsync(task.RecordingUrl); finalRecordingUrl = null; }
                else finalRecordingUrl = request.ExistingRecordingUrl;
            }

            // ── Apply scalars ─────────────────────────────────────────────────
            if (!string.IsNullOrWhiteSpace(request.Title)) task.Title = request.Title.Trim();
            if (parsedStars.HasValue)     task.Stars     = parsedStars.Value;
            if (startDateProvided)        task.StartDate = parsedStartDate;
            if (dueDateProvided)          task.DueDate   = parsedDueDate;
            task.TaskImageUrl = finalTaskImageUrl;
            task.RecordingUrl = finalRecordingUrl;
            task.UpdatedAt    = DateTime.Now;

            await _unitOfWork.ChildTasks.UpdateAsync(task);

            // ── Recurrence ────────────────────────────────────────────────────
            if (parsedIsRecurring.HasValue)
            {
                var existingRec = await _unitOfWork.ChildTaskRecurrences.GetFirstOrDefaultAsync(r => r.TaskId == taskId);
                if (existingRec != null) await _unitOfWork.ChildTaskRecurrences.DeleteAsync(existingRec);

                if (parsedIsRecurring.Value && !string.IsNullOrWhiteSpace(request.RepeatDays))
                {
                    await _unitOfWork.ChildTaskRecurrences.AddAsync(new ChildTaskRecurrence
                    {
                        Id = Guid.NewGuid(),
                        TaskId = task.Id,
                        IsRecurring = true,
                        RepeatDays = request.RepeatDays.ToLowerInvariant().Trim(),
                        RepeatTime = request.RepeatTime
                    });
                }
            }

            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<ChildTaskDetailDto>.SuccessResponse(
                await BuildDetailDtoAsync(task), "تم تحديث المهمة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ChildTaskDetailDto>.FailureResponse(
                "حدث خطأ أثناء تحديث المهمة", new List<string> { ex.Message });
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // F. REMOVE specific child from a task
    //    If last assignee → deletes the entire task + blobs
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<bool>> RemoveChildFromTaskAsync(Guid taskId, Guid childId, Guid requestingUserId)
    {
        try
        {
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null)
                return ApiResponse<bool>.FailureResponse("غير مصرح", new List<string> { "لم يتم العثور على ولي الأمر" });

            var task = await _unitOfWork.ChildTasks.GetByIdAsync(taskId);
            if (task == null || task.ParentId != parent.Id)
                return ApiResponse<bool>.FailureResponse("المهمة غير موجودة", new List<string> { "لم يتم العثور على المهمة" });

            var assignee = (await _unitOfWork.ChildTaskAssignees.FindAsync(
                a => a.TaskId == taskId && a.ChildId == childId)).FirstOrDefault();

            if (assignee == null)
                return ApiResponse<bool>.FailureResponse("الطفل غير مرتبط بهذه المهمة",
                    new List<string> { "هذا الطفل ليس من المحددين في هذه المهمة" });

            await _unitOfWork.ChildTaskAssignees.DeleteAsync(assignee);

            // Check remaining assignees
            var remaining = (await _unitOfWork.ChildTaskAssignees.FindAsync(a => a.TaskId == taskId)).ToList();

            if (remaining.Count == 0)
            {
                // Last child removed → delete the whole task + blobs
                if (!string.IsNullOrEmpty(task.TaskImageUrl))  await _imageService.DeleteBlobByUrlAsync(task.TaskImageUrl);
                if (!string.IsNullOrEmpty(task.RecordingUrl))  await _imageService.DeleteBlobByUrlAsync(task.RecordingUrl);

                var recurrence = await _unitOfWork.ChildTaskRecurrences.GetFirstOrDefaultAsync(r => r.TaskId == taskId);
                if (recurrence != null) await _unitOfWork.ChildTaskRecurrences.DeleteAsync(recurrence);

                await _unitOfWork.ChildTasks.DeleteAsync(task);
            }

            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.SuccessResponse(true,
                remaining.Count == 0 ? "تم حذف المهمة بالكامل (لا يوجد أطفال متبقون)" : "تم إزالة الطفل من المهمة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<bool>.FailureResponse("حدث خطأ", new List<string> { ex.Message });
        }
    }


    // ─────────────────────────────────────────────────────────────────────────
    // H. TOGGLE COMPLETE for a specific child
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<ChildTaskDetailDto>> ToggleChildTaskCompleteAsync(
        Guid taskId, Guid childId, Guid requestingUserId)
    {
        try
        {
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("غير مصرح",
                    new List<string> { "لم يتم العثور على ولي الأمر" });

            var task = await _unitOfWork.ChildTasks.GetByIdAsync(taskId);
            if (task == null || task.ParentId != parent.Id)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("المهمة غير موجودة",
                    new List<string> { "لم يتم العثور على المهمة" });

            var assignee = (await _unitOfWork.ChildTaskAssignees.FindAsync(
                a => a.TaskId == taskId && a.ChildId == childId)).FirstOrDefault();

            if (assignee == null)
                return ApiResponse<ChildTaskDetailDto>.FailureResponse("الطفل غير مرتبط بهذه المهمة",
                    new List<string> { "هذا الطفل ليس من المحددين في هذه المهمة" });

            // Toggle
            if (!assignee.IsCompleted) { assignee.IsCompleted = true;  assignee.CompletedAt = DateTime.Now; }
            else                       { assignee.IsCompleted = false; assignee.CompletedAt = null; }

            task.UpdatedAt = DateTime.Now;
            await _unitOfWork.ChildTaskAssignees.UpdateAsync(assignee);
            await _unitOfWork.ChildTasks.UpdateAsync(task);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<ChildTaskDetailDto>.SuccessResponse(
                await BuildDetailDtoAsync(task),
                assignee.IsCompleted ? "تم إنجاز المهمة لهذا الطفل" : "تم إلغاء إنجاز المهمة لهذا الطفل");
        }
        catch (Exception ex)
        {
            return ApiResponse<ChildTaskDetailDto>.FailureResponse(
                "حدث خطأ أثناء تحديث حالة المهمة", new List<string> { ex.Message });
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // I. GET SUMMARY
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<ChildTaskSummaryDto>> GetChildTaskSummaryAsync(Guid parentId, Guid requestingUserId)
    {
        try
        {
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null || parent.Id != parentId)
                return ApiResponse<ChildTaskSummaryDto>.FailureResponse("غير مصرح",
                    new List<string> { "لا يمكنك الوصول إلى بيانات هذا المستخدم" });

            var allTasks = (await _unitOfWork.ChildTasks.FindAsync(ct => ct.ParentId == parentId)).ToList();
            var allAssignees = new List<ChildTaskAssignee>();
            foreach (var task in allTasks)
                allAssignees.AddRange(await _unitOfWork.ChildTaskAssignees.FindAsync(a => a.TaskId == task.Id));

            var todayUtc = DateTime.UtcNow.Date;
            var childIds = allAssignees.Select(a => a.ChildId).Distinct().ToList();
            var perChild = new List<ChildSummaryItemDto>();

            foreach (var childId in childIds)
            {
                var child = await _unitOfWork.Children.GetByIdAsync(childId);
                if (child == null) continue;

                var childAssignees = allAssignees.Where(a => a.ChildId == childId).ToList();

                perChild.Add(new ChildSummaryItemDto
                {
                    ChildId = child.Id, FullName = child.FullName, ProfileImageUrl = child.ProfileImageUrl,
                    TotalStars = childAssignees
                        .Where(a => a.IsCompleted)
                        .Join(allTasks, a => a.TaskId, t => t.Id, (a, t) => t.Stars)
                        .Sum(),
                    PendingTasksCount   = childAssignees.Count(a => !a.IsCompleted),
                    CompletedTasksCount = childAssignees.Count(a => a.IsCompleted)
                });
            }

            // Global totals across unique tasks (a task counts once regardless of how many children it has)
            return ApiResponse<ChildTaskSummaryDto>.SuccessResponse(
                new ChildTaskSummaryDto
                {
                    TotalChildTasks     = allTasks.Count,
                    TotalPendingTasks   = allAssignees.Count(a => !a.IsCompleted),
                    TotalCompletedTasks = allAssignees.Count(a => a.IsCompleted),
                    CompletedToday      = allAssignees.Count(a =>
                        a.IsCompleted && a.CompletedAt.HasValue &&
                        a.CompletedAt.Value.ToUniversalTime().Date == todayUtc),
                    PerChild = perChild
                }, "تم جلب الملخص بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ChildTaskSummaryDto>.FailureResponse(
                "حدث خطأ أثناء جلب الملخص", new List<string> { ex.Message });
        }
    }
}
