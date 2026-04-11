using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Task;
using Ajial.Application.DTOs.TaskCategory;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Service;

public class TaskCategoryService : ITaskCategoryService
{
    private readonly IUnitOfWork _unitOfWork;

    public TaskCategoryService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<ApiResponse<GetCategoriesResponseDto>> GetCategoriesAsync(Guid parentId, Guid requestingUserId)
    {
        try
        {
            // Step 1: Validate that parentId belongs to the requesting user
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null || parent.Id != parentId)
            {
                return ApiResponse<GetCategoriesResponseDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "لا يمكنك الوصول إلى بيانات هذا المستخدم" }
                );
            }

            // Step 2: Get all categories for this parent — seed defaults if none exist yet
            var categories = (await _unitOfWork.TaskCategories.FindAsync(tc => tc.ParentId == parentId))
                .ToList();

            if (categories.Count == 0)
            {
                var defaults = new[]
                {
                    new TaskCategory { Id = Guid.NewGuid(), ParentId = parentId, Name = "الكل",              IsSystem = true,  CreatedAt = DateTime.Now },
                    new TaskCategory { Id = Guid.NewGuid(), ParentId = parentId, Name = "متطلبات المنزل",    IsSystem = false, CreatedAt = DateTime.Now },
                    new TaskCategory { Id = Guid.NewGuid(), ParentId = parentId, Name = "دواء",              IsSystem = false, CreatedAt = DateTime.Now },
                    new TaskCategory { Id = Guid.NewGuid(), ParentId = parentId, Name = "كشف",              IsSystem = false, CreatedAt = DateTime.Now },
                };
                foreach (var cat in defaults)
                    await _unitOfWork.TaskCategories.AddAsync(cat);
                await _unitOfWork.SaveChangesAsync();
                categories = defaults.ToList();
            }

            // Step 3: Get all tasks for this parent to compute counts
            var allTasks = (await _unitOfWork.Tasks.FindAsync(t => t.ParentId == parentId))
                .ToList();

            int totalTaskCount = allTasks.Count;

            // Step 4: Build response — system "الكل" first, then others
            var categoryItems = categories
                .OrderByDescending(tc => tc.IsSystem)
                .ThenBy(tc => tc.CreatedAt)
                .Select(tc => new CategoryItemDto
                {
                    Id = tc.Id,
                    Name = tc.Name,
                    IsSystem = tc.IsSystem,
                    TaskCount = tc.IsSystem
                        ? totalTaskCount
                        : allTasks.Count(t => t.CategoryId == tc.Id)
                })
                .ToList();

            return ApiResponse<GetCategoriesResponseDto>.SuccessResponse(
                new GetCategoriesResponseDto { Categories = categoryItems },
                "تم جلب التصنيفات بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<GetCategoriesResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب التصنيفات",
                new List<string> { ex.Message }
            );
        }
    }

    public async Task<ApiResponse<TaskCategoryDto>> CreateCategoryAsync(CreateCategoryRequestDto request, Guid requestingUserId)
    {
        try
        {
            // Step 1: Get parent
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null)
            {
                return ApiResponse<TaskCategoryDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "لم يتم العثور على ولي الأمر" }
                );
            }

            var trimmedName = request.Name.Trim();

            // Step 2: Check for duplicate name (case-insensitive) for this parent
            var duplicate = await _unitOfWork.TaskCategories.ExistsAsync(
                tc => tc.ParentId == parent.Id &&
                      tc.Name.ToLower() == trimmedName.ToLower()
            );
            if (duplicate)
            {
                return ApiResponse<TaskCategoryDto>.FailureResponse(
                    "التصنيف موجود بالفعل",
                    new List<string> { "يوجد تصنيف بنفس الاسم مسبقاً" }
                );
            }

            // Step 3: Create category
            var category = new TaskCategory
            {
                Id = Guid.NewGuid(),
                ParentId = parent.Id,
                Name = trimmedName,
                IsSystem = false,
                CreatedAt = DateTime.Now
            };

            await _unitOfWork.TaskCategories.AddAsync(category);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<TaskCategoryDto>.SuccessResponse(
                new TaskCategoryDto { Id = category.Id, Name = category.Name },
                "تم إضافة التصنيف بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<TaskCategoryDto>.FailureResponse(
                "حدث خطأ أثناء إضافة التصنيف",
                new List<string> { ex.Message }
            );
        }
    }

    public async Task<ApiResponse<TaskCategoryDto>> UpdateCategoryAsync(Guid categoryId, UpdateCategoryRequestDto request, Guid requestingUserId)
    {
        try
        {
            // Step 1: Get parent
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
            if (parent == null)
            {
                return ApiResponse<TaskCategoryDto>.FailureResponse(
                    "غير مصرح",
                    new List<string> { "لم يتم العثور على ولي الأمر" }
                );
            }

            // Step 2: Get category and validate ownership
            var category = await _unitOfWork.TaskCategories.GetByIdAsync(categoryId);
            if (category == null || category.ParentId != parent.Id)
            {
                return ApiResponse<TaskCategoryDto>.FailureResponse(
                    "التصنيف غير موجود",
                    new List<string> { "لم يتم العثور على التصنيف" }
                );
            }

            // Step 3: Reject system categories
            if (category.IsSystem)
            {
                return ApiResponse<TaskCategoryDto>.FailureResponse(
                    "لا يمكن تعديل هذا التصنيف",
                    new List<string> { "التصنيفات الافتراضية لا يمكن تعديلها" }
                );
            }

            var trimmedName = request.Name.Trim();

            // Step 4: Check for duplicate name (excluding this category)
            var duplicate = await _unitOfWork.TaskCategories.ExistsAsync(
                tc => tc.ParentId == parent.Id &&
                      tc.Id != categoryId &&
                      tc.Name.ToLower() == trimmedName.ToLower()
            );
            if (duplicate)
            {
                return ApiResponse<TaskCategoryDto>.FailureResponse(
                    "التصنيف موجود بالفعل",
                    new List<string> { "يوجد تصنيف بنفس الاسم مسبقاً" }
                );
            }

            // Step 5: Update
            category.Name = trimmedName;
            category.UpdatedAt = DateTime.Now;
            await _unitOfWork.TaskCategories.UpdateAsync(category);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<TaskCategoryDto>.SuccessResponse(
                new TaskCategoryDto { Id = category.Id, Name = category.Name },
                "تم تحديث التصنيف بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<TaskCategoryDto>.FailureResponse(
                "حدث خطأ أثناء تحديث التصنيف",
                new List<string> { ex.Message }
            );
        }
    }

    public async Task<ApiResponse<bool>> DeleteCategoryAsync(Guid categoryId, Guid requestingUserId)
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

            // Step 2: Get category and validate ownership
            var category = await _unitOfWork.TaskCategories.GetByIdAsync(categoryId);
            if (category == null || category.ParentId != parent.Id)
            {
                return ApiResponse<bool>.FailureResponse(
                    "التصنيف غير موجود",
                    new List<string> { "لم يتم العثور على التصنيف" }
                );
            }

            // Step 3: Reject system categories
            if (category.IsSystem)
            {
                return ApiResponse<bool>.FailureResponse(
                    "لا يمكن حذف هذا التصنيف",
                    new List<string> { "التصنيفات الافتراضية لا يمكن حذفها" }
                );
            }

            // Step 4: Null out CategoryId on all tasks that use this category (in same transaction)
            var affectedTasks = (await _unitOfWork.Tasks.FindAsync(t => t.CategoryId == categoryId))
                .ToList();

            foreach (var task in affectedTasks)
            {
                task.CategoryId = null;
                task.UpdatedAt = DateTime.Now;
                await _unitOfWork.Tasks.UpdateAsync(task);
            }

            // Step 5: Delete category
            await _unitOfWork.TaskCategories.DeleteAsync(category);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.SuccessResponse(true, "تم حذف التصنيف بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<bool>.FailureResponse(
                "حدث خطأ أثناء حذف التصنيف",
                new List<string> { ex.Message }
            );
        }
    }
}
