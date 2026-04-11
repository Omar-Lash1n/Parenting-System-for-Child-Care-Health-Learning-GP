using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Task;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Service;

public class TaskService : ITaskService
{
    private readonly IUnitOfWork _unitOfWork;

    public TaskService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GET Tasks
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<GetTasksResponseDto>> GetTasksAsync(Guid parentId, Guid requestingUserId)
    {
        try
        {
            // Step 1: Validate ownership
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null || parent.Id != parentId)
            {
                return ApiResponse<GetTasksResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "لا يمكنك الوصول إلى بيانات هذا المستخدم" }
                );
            }

            // Step 2: Load tasks with their assignees
            var tasks = (await _unitOfWork.Tasks.FindAsync(t => t.ParentId == parentId))
                .ToList();

            // Step 3: Load system "الكل" category for fallback
            var systemCategory = await _unitOfWork.TaskCategories.GetFirstOrDefaultAsync(
                tc => tc.ParentId == parentId && tc.IsSystem
            );

            // Step 4: Build parent info for assignee DTOs
            var parentUser = await _unitOfWork.Users.GetByIdAsync(parent.UserId);

            // Step 5: Load all children for this parent (for assignee lookup)
            var children = (await _unitOfWork.Children.FindAsync(c => c.ParentId == parentId))
                .ToDictionary(c => c.Id);

            // Step 6: Load all categories for this parent (for category lookup)
            var categories = (await _unitOfWork.TaskCategories.FindAsync(tc => tc.ParentId == parentId))
                .ToDictionary(tc => tc.Id);

            var taskCards = new List<TaskCardDto>();

            foreach (var task in tasks)
            {
                // Resolve category
                TaskCategoryDto categoryDto;
                if (task.CategoryId.HasValue && categories.TryGetValue(task.CategoryId.Value, out var cat))
                {
                    categoryDto = new TaskCategoryDto { Id = cat.Id, Name = cat.Name };
                }
                else if (systemCategory != null)
                {
                    categoryDto = new TaskCategoryDto { Id = systemCategory.Id, Name = systemCategory.Name };
                }
                else
                {
                    categoryDto = new TaskCategoryDto { Id = Guid.Empty, Name = "الكل" };
                }

                // Build assignees list
                var assignees = new List<TaskAssigneeDto>();

                if (task.IncludeParent && parentUser != null)
                {
                    assignees.Add(new TaskAssigneeDto
                    {
                        Type = "parent",
                        Id = parent.Id,
                        FullName = parentUser.FullName,
                        ProfileImageUrl = parent.ProfileImageUrl
                    });
                }

                // Load child assignees for this task
                var taskAssignees = (await _unitOfWork.TaskAssignees.FindAsync(ta => ta.TaskId == task.Id))
                    .ToList();

                foreach (var ta in taskAssignees)
                {
                    if (children.TryGetValue(ta.ChildId, out var child))
                    {
                        assignees.Add(new TaskAssigneeDto
                        {
                            Type = "child",
                            Id = child.Id,
                            FullName = child.FullName,
                            ProfileImageUrl = child.ProfileImageUrl
                        });
                    }
                }

                taskCards.Add(new TaskCardDto
                {
                    Id = task.Id,
                    Title = task.Title,
                    Color = task.Color,
                    DueDate = task.DueDate,
                    IsCompleted = task.IsCompleted,
                    CompletedAt = task.CompletedAt,
                    Category = categoryDto,
                    Assignees = assignees
                });
            }

            return ApiResponse<GetTasksResponseDto>.SuccessResponse(
                new GetTasksResponseDto { Tasks = taskCards },
                "تم جلب المهام بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<GetTasksResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب المهام",
                new List<string> { ex.Message }
            );
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GET Task By ID  (عرض التفاصيل)
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<TaskCardDto>> GetTaskByIdAsync(Guid taskId, Guid requestingUserId)
    {
        try
        {
            // Step 1: Validate parent
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null)
            {
                return ApiResponse<TaskCardDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "لم يتم العثور على ولي الأمر" }
                );
            }

            // Step 2: Load task and verify ownership
            var task = await _unitOfWork.Tasks.GetByIdAsync(taskId);
            if (task == null || task.ParentId != parent.Id)
            {
                return ApiResponse<TaskCardDto>.FailureResponse(
                    "المهمة غير موجودة",
                    new List<string> { "لم يتم العثور على المهمة" }
                );
            }

            return ApiResponse<TaskCardDto>.SuccessResponse(
                await BuildTaskCardAsync(task, parent),
                "تم جلب تفاصيل المهمة بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<TaskCardDto>.FailureResponse(
                "حدث خطأ أثناء جلب تفاصيل المهمة",
                new List<string> { ex.Message }
            );
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // GET Done Tasks  (المهام المنجزة)
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<GetDoneTasksResponseDto>> GetDoneTasksAsync(Guid parentId, Guid requestingUserId)
    {
        try
        {
            // Step 1: Validate ownership
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null || parent.Id != parentId)
            {
                return ApiResponse<GetDoneTasksResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "لا يمكنك الوصول إلى بيانات هذا المستخدم" }
                );
            }

            // Step 2: Load completed tasks, sorted newest first by CompletedAt
            var doneTasks = (await _unitOfWork.Tasks.FindAsync(
                    t => t.ParentId == parentId && t.IsCompleted))
                .OrderByDescending(t => t.CompletedAt)
                .ToList();

            // Step 3: Build TaskCardDto for each
            var taskCards = new List<TaskCardDto>();
            foreach (var task in doneTasks)
            {
                taskCards.Add(await BuildTaskCardAsync(task, parent));
            }

            return ApiResponse<GetDoneTasksResponseDto>.SuccessResponse(
                new GetDoneTasksResponseDto
                {
                    Tasks = taskCards,
                    TotalCount = taskCards.Count
                },
                "تم جلب المهام المنجزة بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<GetDoneTasksResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب المهام المنجزة",
                new List<string> { ex.Message }
            );
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CREATE Task
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<TaskCardDto>> CreateTaskAsync(CreateTaskRequestDto request, Guid requestingUserId)
    {
        try
        {
            // Step 1: Get parent
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null)
            {
                return ApiResponse<TaskCardDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "لم يتم العثور على ولي الأمر" }
                );
            }

            // Step 2: Validate categoryId if provided
            if (request.CategoryId.HasValue)
            {
                var categoryExists = await _unitOfWork.TaskCategories.ExistsAsync(
                    tc => tc.Id == request.CategoryId.Value && tc.ParentId == parent.Id
                );
                if (!categoryExists)
                {
                    return ApiResponse<TaskCardDto>.FailureResponse(
                        "التصنيف غير موجود",
                        new List<string> { "التصنيف المحدد غير موجود" }
                    );
                }
            }

            // Step 3: Validate each childId belongs to this parent
            foreach (var childId in request.ChildIds)
            {
                var childBelongsToParent = await _unitOfWork.Children.ExistsAsync(
                    c => c.Id == childId && c.ParentId == parent.Id
                );
                if (!childBelongsToParent)
                {
                    return ApiResponse<TaskCardDto>.FailureResponse(
                        "طفل غير موجود",
                        new List<string> { $"الطفل المحدد غير موجود ضمن أطفالك" }
                    );
                }
            }

            // Step 4: Determine DueDate and IsPushSent
            bool dueDateProvided = request.DueDate.HasValue;
            DateTime dueDate = dueDateProvided ? request.DueDate!.Value : DateTime.Today;
            bool isPushSent = !dueDateProvided; // suppress notification when defaulting to today

            // Step 5: Create task
            var task = new ParentTask
            {
                Id = Guid.NewGuid(),
                ParentId = parent.Id,
                CategoryId = request.CategoryId,
                Title = request.Title.Trim(),
                Color = request.Color?.Trim(),
                DueDate = dueDate,
                IncludeParent = request.IncludeParent,
                IsCompleted = false,
                CompletedAt = null,
                IsPushSent = isPushSent,
                CreatedAt = DateTime.Now
            };

            await _unitOfWork.Tasks.AddAsync(task);

            // Step 6: Create TaskAssignee rows
            foreach (var childId in request.ChildIds)
            {
                await _unitOfWork.TaskAssignees.AddAsync(new TaskAssignee
                {
                    TaskId = task.Id,
                    ChildId = childId
                });
            }

            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<TaskCardDto>.SuccessResponse(
                await BuildTaskCardAsync(task, parent),
                "تم إضافة المهمة بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<TaskCardDto>.FailureResponse(
                "حدث خطأ أثناء إضافة المهمة",
                new List<string> { ex.Message }
            );
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // UPDATE Task
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<TaskCardDto>> UpdateTaskAsync(Guid taskId, UpdateTaskRequestDto request, Guid requestingUserId)
    {
        try
        {
            // Step 1: Get parent
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null)
            {
                return ApiResponse<TaskCardDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "لم يتم العثور على ولي الأمر" }
                );
            }

            // Step 2: Get task and validate ownership
            var task = await _unitOfWork.Tasks.GetByIdAsync(taskId);
            if (task == null || task.ParentId != parent.Id)
            {
                return ApiResponse<TaskCardDto>.FailureResponse(
                    "المهمة غير موجودة",
                    new List<string> { "لم يتم العثور على المهمة" }
                );
            }

            // Step 3: Validate categoryId if provided
            if (request.CategoryId.HasValue)
            {
                var categoryExists = await _unitOfWork.TaskCategories.ExistsAsync(
                    tc => tc.Id == request.CategoryId.Value && tc.ParentId == parent.Id
                );
                if (!categoryExists)
                {
                    return ApiResponse<TaskCardDto>.FailureResponse(
                        "التصنيف غير موجود",
                        new List<string> { "التصنيف المحدد غير موجود" }
                    );
                }
            }

            // Step 4: Validate each childId
            foreach (var childId in request.ChildIds)
            {
                var childBelongsToParent = await _unitOfWork.Children.ExistsAsync(
                    c => c.Id == childId && c.ParentId == parent.Id
                );
                if (!childBelongsToParent)
                {
                    return ApiResponse<TaskCardDto>.FailureResponse(
                        "طفل غير موجود",
                        new List<string> { "الطفل المحدد غير موجود ضمن أطفالك" }
                    );
                }
            }

            // Step 5: Determine IsPushSent based on dueDate change
            bool dueDateProvided = request.DueDate.HasValue;
            DateTime newDueDate = dueDateProvided ? request.DueDate!.Value : DateTime.Today;

            bool newIsPushSent;
            if (!dueDateProvided)
            {
                // Client sent null → suppress notification
                newIsPushSent = true;
            }
            else if (task.IsPushSent && task.DueDate != newDueDate)
            {
                // Explicit new date different from previous → re-enable notification
                newIsPushSent = false;
            }
            else
            {
                // Keep existing flag
                newIsPushSent = task.IsPushSent;
            }

            // Step 6: Update task fields
            task.Title = request.Title.Trim();
            task.CategoryId = request.CategoryId;
            task.Color = request.Color?.Trim();
            task.DueDate = newDueDate;
            task.IncludeParent = request.IncludeParent;
            task.IsPushSent = newIsPushSent;
            task.UpdatedAt = DateTime.Now;

            await _unitOfWork.Tasks.UpdateAsync(task);

            // Step 7: Replace TaskAssignee rows (delete all + re-insert)
            var existingAssignees = (await _unitOfWork.TaskAssignees.FindAsync(ta => ta.TaskId == taskId))
                .ToList();

            foreach (var existing in existingAssignees)
            {
                await _unitOfWork.TaskAssignees.DeleteAsync(existing);
            }

            foreach (var childId in request.ChildIds)
            {
                await _unitOfWork.TaskAssignees.AddAsync(new TaskAssignee
                {
                    TaskId = task.Id,
                    ChildId = childId
                });
            }

            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<TaskCardDto>.SuccessResponse(
                await BuildTaskCardAsync(task, parent),
                "تم تحديث المهمة بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<TaskCardDto>.FailureResponse(
                "حدث خطأ أثناء تحديث المهمة",
                new List<string> { ex.Message }
            );
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // DELETE Task
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<bool>> DeleteTaskAsync(Guid taskId, Guid requestingUserId)
    {
        try
        {
            // Step 1: Get parent
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null)
            {
                return ApiResponse<bool>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "لم يتم العثور على ولي الأمر" }
                );
            }

            // Step 2: Get task and validate ownership
            var task = await _unitOfWork.Tasks.GetByIdAsync(taskId);
            if (task == null || task.ParentId != parent.Id)
            {
                return ApiResponse<bool>.FailureResponse(
                    "المهمة غير موجودة",
                    new List<string> { "لم يتم العثور على المهمة" }
                );
            }

            // Step 3: Delete assignees first (cascade is configured in EF, but explicit for clarity)
            var assignees = (await _unitOfWork.TaskAssignees.FindAsync(ta => ta.TaskId == taskId))
                .ToList();

            foreach (var assignee in assignees)
            {
                await _unitOfWork.TaskAssignees.DeleteAsync(assignee);
            }

            // Step 4: Delete task
            await _unitOfWork.Tasks.DeleteAsync(task);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.SuccessResponse(true, "تم حذف المهمة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<bool>.FailureResponse(
                "حدث خطأ أثناء حذف المهمة",
                new List<string> { ex.Message }
            );
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TOGGLE COMPLETE
    // ─────────────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<TaskCardDto>> ToggleCompleteAsync(Guid taskId, Guid requestingUserId)
    {
        try
        {
            // Step 1: Get parent
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null)
            {
                return ApiResponse<TaskCardDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "لم يتم العثور على ولي الأمر" }
                );
            }

            // Step 2: Get task and validate ownership
            var task = await _unitOfWork.Tasks.GetByIdAsync(taskId);
            if (task == null || task.ParentId != parent.Id)
            {
                return ApiResponse<TaskCardDto>.FailureResponse(
                    "المهمة غير موجودة",
                    new List<string> { "لم يتم العثور على المهمة" }
                );
            }

            // Step 3: Toggle
            if (!task.IsCompleted)
            {
                task.IsCompleted = true;
                task.CompletedAt = DateTime.Now;
            }
            else
            {
                task.IsCompleted = false;
                task.CompletedAt = null;
            }

            task.UpdatedAt = DateTime.Now;
            await _unitOfWork.Tasks.UpdateAsync(task);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<TaskCardDto>.SuccessResponse(
                await BuildTaskCardAsync(task, parent),
                task.IsCompleted ? "تم إنجاز المهمة" : "تم إلغاء إنجاز المهمة"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<TaskCardDto>.FailureResponse(
                "حدث خطأ أثناء تحديث حالة المهمة",
                new List<string> { ex.Message }
            );
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // HELPER: Build TaskCardDto
    // ─────────────────────────────────────────────────────────────────────────

    private async Task<TaskCardDto> BuildTaskCardAsync(ParentTask task, Parent parent)
    {
        // Resolve category
        TaskCategoryDto categoryDto;
        if (task.CategoryId.HasValue)
        {
            var cat = await _unitOfWork.TaskCategories.GetByIdAsync(task.CategoryId.Value);
            categoryDto = cat != null
                ? new TaskCategoryDto { Id = cat.Id, Name = cat.Name }
                : await GetSystemCategoryDtoAsync(parent.Id);
        }
        else
        {
            categoryDto = await GetSystemCategoryDtoAsync(parent.Id);
        }

        // Build assignees
        var assignees = new List<TaskAssigneeDto>();

        if (task.IncludeParent)
        {
            var parentUser = await _unitOfWork.Users.GetByIdAsync(parent.UserId);
            if (parentUser != null)
            {
                assignees.Add(new TaskAssigneeDto
                {
                    Type = "parent",
                    Id = parent.Id,
                    FullName = parentUser.FullName,
                    ProfileImageUrl = parent.ProfileImageUrl
                });
            }
        }

        var taskAssignees = (await _unitOfWork.TaskAssignees.FindAsync(ta => ta.TaskId == task.Id))
            .ToList();

        foreach (var ta in taskAssignees)
        {
            var child = await _unitOfWork.Children.GetByIdAsync(ta.ChildId);
            if (child != null)
            {
                assignees.Add(new TaskAssigneeDto
                {
                    Type = "child",
                    Id = child.Id,
                    FullName = child.FullName,
                    ProfileImageUrl = child.ProfileImageUrl
                });
            }
        }

        return new TaskCardDto
        {
            Id = task.Id,
            Title = task.Title,
            Color = task.Color,
            DueDate = task.DueDate,
            IsCompleted = task.IsCompleted,
            CompletedAt = task.CompletedAt,
            Category = categoryDto,
            Assignees = assignees
        };
    }

    private async Task<TaskCategoryDto> GetSystemCategoryDtoAsync(Guid parentId)
    {
        var systemCategory = await _unitOfWork.TaskCategories.GetFirstOrDefaultAsync(
            tc => tc.ParentId == parentId && tc.IsSystem
        );
        return systemCategory != null
            ? new TaskCategoryDto { Id = systemCategory.Id, Name = systemCategory.Name }
            : new TaskCategoryDto { Id = Guid.Empty, Name = "الكل" };
    }
}
