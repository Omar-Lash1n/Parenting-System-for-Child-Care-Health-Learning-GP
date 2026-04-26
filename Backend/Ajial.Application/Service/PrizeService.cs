using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Prize;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;
using PrizeEntity = Ajial.Domain.Entities.Prize;

namespace Ajial.Application.Service;

public class PrizeService : IPrizeService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IImageService _imageService;

    public PrizeService(IUnitOfWork unitOfWork, IImageService imageService)
    {
        _unitOfWork = unitOfWork;
        _imageService = imageService;
    }

    private static readonly List<string> UnauthorizedErrors = new()
    {
        "غير مصرح — لا يمكنك الوصول إلى بيانات هذا المستخدم"
    };

    private async Task<Parent?> GetParentAsync(Guid requestingUserId)
    {
        return await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == requestingUserId);
    }

    private async Task<int> GetChildTotalStarsAsync(Guid childId)
    {
        var childAssignees = (await _unitOfWork.ChildTaskAssignees.FindAsync(a => a.ChildId == childId && a.IsCompleted)).ToList();
        var totalStars = 0;

        foreach (var assignee in childAssignees)
        {
            var task = await _unitOfWork.ChildTasks.GetByIdAsync(assignee.TaskId);
            if (task != null) totalStars += task.Stars;
        }

        return totalStars;
    }

    private async Task<(int currentStars, int remainingStars, int completedTasksCount, int totalRequiredTasks, string status, bool canDeliver)>
        GetProgressAsync(PrizeEntity prize)
    {
        var currentStars = await GetChildTotalStarsAsync(prize.ChildId);
        var remainingStars = Math.Max(0, prize.RequiredStars - currentStars);
        var requiredTasks = (await _unitOfWork.PrizeTasks.FindAsync(pt => pt.PrizeId == prize.Id)).ToList();
        var totalRequiredTasks = requiredTasks.Count;
        var completedTasksCount = 0;

        foreach (var requiredTask in requiredTasks)
        {
            var assignee = await _unitOfWork.ChildTaskAssignees.GetFirstOrDefaultAsync(a =>
                a.ChildId == prize.ChildId &&
                a.TaskId == requiredTask.TaskId &&
                a.IsCompleted);

            if (assignee != null) completedTasksCount++;
        }

        var allTasksCompleted = completedTasksCount == totalRequiredTasks;
        var effectiveStatus = prize.Status == PrizeStatus.Delivered
            ? PrizeStatus.Delivered
            : allTasksCompleted && currentStars >= prize.RequiredStars
                ? PrizeStatus.Ready
                : PrizeStatus.Active;

        return (
            currentStars,
            remainingStars,
            completedTasksCount,
            totalRequiredTasks,
            effectiveStatus.ToString(),
            effectiveStatus == PrizeStatus.Ready
        );
    }

    private async Task<PrizeCardDto> BuildCardDtoAsync(PrizeEntity prize)
    {
        var progress = await GetProgressAsync(prize);
        return new PrizeCardDto
        {
            PrizeId = prize.Id,
            Title = prize.Title,
            ImageUrl = prize.ImageUrl,
            RequiredStars = prize.RequiredStars,
            CurrentStars = progress.currentStars,
            RemainingStars = progress.remainingStars,
            CompletedTasksCount = progress.completedTasksCount,
            TotalRequiredTasks = progress.totalRequiredTasks,
            Status = progress.status,
            CanDeliver = progress.canDeliver
        };
    }

    private async Task<PrizeDetailDto> BuildDetailDtoAsync(PrizeEntity prize)
    {
        var child = await _unitOfWork.Children.GetByIdAsync(prize.ChildId);
        var progress = await GetProgressAsync(prize);
        var requiredTasks = (await _unitOfWork.PrizeTasks.FindAsync(pt => pt.PrizeId == prize.Id)).ToList();
        var taskDtos = new List<PrizeTaskDto>();

        foreach (var prizeTask in requiredTasks)
        {
            var task = await _unitOfWork.ChildTasks.GetByIdAsync(prizeTask.TaskId);
            if (task == null) continue;

            var assignee = await _unitOfWork.ChildTaskAssignees.GetFirstOrDefaultAsync(a =>
                a.ChildId == prize.ChildId && a.TaskId == task.Id);

            taskDtos.Add(new PrizeTaskDto
            {
                TaskId = task.Id,
                Title = task.Title,
                TaskImageUrl = task.TaskImageUrl,
                Stars = task.Stars,
                IsCompleted = assignee?.IsCompleted ?? false,
                CompletedAt = assignee?.CompletedAt
            });
        }

        return new PrizeDetailDto
        {
            PrizeId = prize.Id,
            Title = prize.Title,
            ImageUrl = prize.ImageUrl,
            RequiredStars = prize.RequiredStars,
            CurrentStars = progress.currentStars,
            RemainingStars = progress.remainingStars,
            CompletedTasksCount = progress.completedTasksCount,
            TotalRequiredTasks = progress.totalRequiredTasks,
            Status = progress.status,
            CanDeliver = progress.canDeliver,
            ChildId = prize.ChildId,
            ChildFullName = child?.FullName ?? string.Empty,
            ChildProfileImageUrl = child?.ProfileImageUrl,
            RequiredTasks = taskDtos,
            CreatedAt = prize.CreatedAt,
            UpdatedAt = prize.UpdatedAt,
            DeliveredAt = prize.DeliveredAt
        };
    }

    private async Task<bool> TaskBelongsToChildAsync(Guid taskId, Guid childId, Guid parentId)
    {
        var task = await _unitOfWork.ChildTasks.GetByIdAsync(taskId);
        if (task == null || task.ParentId != parentId) return false;

        var assignee = await _unitOfWork.ChildTaskAssignees.GetFirstOrDefaultAsync(a =>
            a.TaskId == taskId && a.ChildId == childId);

        return assignee != null;
    }

    private async Task<bool> ValidateTasksBelongToChildAsync(IEnumerable<Guid> taskIds, Guid childId, Guid parentId)
    {
        foreach (var taskId in taskIds)
        {
            if (!await TaskBelongsToChildAsync(taskId, childId, parentId))
                return false;
        }

        return true;
    }

    public async Task<ApiResponse<PrizeDetailDto>> CreatePrizeAsync(CreatePrizeRequestDto request, Guid requestingUserId)
    {
        try
        {
            var parent = await GetParentAsync(requestingUserId);
            if (parent == null)
                return ApiResponse<PrizeDetailDto>.FailureResponse("غير مصرح", UnauthorizedErrors);

            if (string.IsNullOrWhiteSpace(request.Title))
                return ApiResponse<PrizeDetailDto>.FailureResponse("عنوان الجائزة مطلوب",
                    new List<string> { "عنوان الجائزة مطلوب" });

            var child = await _unitOfWork.Children.GetByIdAsync(request.ChildId);
            if (child == null || child.ParentId != parent.Id)
                return ApiResponse<PrizeDetailDto>.FailureResponse("الطفل المحدد غير موجود ضمن أطفالك",
                    new List<string> { "الطفل المحدد غير موجود ضمن أطفالك" });

            if (!child.IsActive)
                return ApiResponse<PrizeDetailDto>.FailureResponse("حساب الطفل غير مفعل",
                    new List<string> { "حساب الطفل غير مفعل" });

            if (request.RequiredStars <= 0)
                return ApiResponse<PrizeDetailDto>.FailureResponse("عدد النجوم المطلوبة يجب أن يكون أكبر من صفر",
                    new List<string> { "عدد النجوم المطلوبة يجب أن يكون أكبر من صفر" });

            var taskIds = request.TaskIds?.Distinct().ToList() ?? new List<Guid>();
            if (taskIds.Count == 0)
                return ApiResponse<PrizeDetailDto>.FailureResponse("يجب اختيار مهمة واحدة على الأقل",
                    new List<string> { "يجب اختيار مهمة واحدة على الأقل" });

            if (!await ValidateTasksBelongToChildAsync(taskIds, child.Id, parent.Id))
                return ApiResponse<PrizeDetailDto>.FailureResponse("المهمة المحددة غير موجودة أو لا تخص هذا الطفل",
                    new List<string> { "المهمة المحددة غير موجودة أو لا تخص هذا الطفل" });

            string? imageUrl = null;
            if (request.PrizeImage != null && request.PrizeImage.Length > 0)
            {
                try { imageUrl = await _imageService.UploadPrizeImageAsync(request.PrizeImage, requestingUserId); }
                catch (ArgumentException ex)
                {
                    return ApiResponse<PrizeDetailDto>.FailureResponse("خطأ في ملف الصورة", new List<string> { ex.Message });
                }
            }

            var prize = new PrizeEntity
            {
                Id = Guid.NewGuid(),
                ParentId = parent.Id,
                ChildId = child.Id,
                Title = request.Title.Trim(),
                ImageUrl = imageUrl,
                RequiredStars = request.RequiredStars,
                Status = PrizeStatus.Active,
                CreatedAt = DateTime.Now
            };

            await _unitOfWork.Prizes.AddAsync(prize);
            foreach (var taskId in taskIds)
            {
                await _unitOfWork.PrizeTasks.AddAsync(new PrizeTask
                {
                    PrizeId = prize.Id,
                    TaskId = taskId
                });
            }

            await _unitOfWork.SaveChangesAsync();
            return ApiResponse<PrizeDetailDto>.SuccessResponse(await BuildDetailDtoAsync(prize), "تم إضافة الجائزة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<PrizeDetailDto>.FailureResponse("حدث خطأ أثناء إضافة الجائزة", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<GetPrizesForChildResponseDto>> GetPrizesForChildAsync(Guid childId, Guid requestingUserId)
    {
        try
        {
            var parent = await GetParentAsync(requestingUserId);
            if (parent == null)
                return ApiResponse<GetPrizesForChildResponseDto>.FailureResponse("غير مصرح", UnauthorizedErrors);

            var child = await _unitOfWork.Children.GetByIdAsync(childId);
            if (child == null || child.ParentId != parent.Id)
                return ApiResponse<GetPrizesForChildResponseDto>.FailureResponse("الطفل المحدد غير موجود ضمن أطفالك",
                    new List<string> { "الطفل المحدد غير موجود ضمن أطفالك" });

            if (!child.IsActive)
                return ApiResponse<GetPrizesForChildResponseDto>.FailureResponse("حساب الطفل غير مفعل",
                    new List<string> { "حساب الطفل غير مفعل" });

            var prizes = (await _unitOfWork.Prizes.FindAsync(p => p.ChildId == childId && p.ParentId == parent.Id))
                .OrderByDescending(p => p.CreatedAt)
                .ToList();

            var cards = new List<PrizeCardDto>();
            foreach (var prize in prizes)
                cards.Add(await BuildCardDtoAsync(prize));

            return ApiResponse<GetPrizesForChildResponseDto>.SuccessResponse(new GetPrizesForChildResponseDto
            {
                ChildId = child.Id,
                ChildFullName = child.FullName,
                TotalStars = await GetChildTotalStarsAsync(child.Id),
                Prizes = cards
            }, "تم جلب الجوائز بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<GetPrizesForChildResponseDto>.FailureResponse("حدث خطأ أثناء جلب الجوائز", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<PrizeDetailDto>> GetPrizeByIdAsync(Guid prizeId, Guid requestingUserId)
    {
        try
        {
            var parent = await GetParentAsync(requestingUserId);
            if (parent == null)
                return ApiResponse<PrizeDetailDto>.FailureResponse("غير مصرح", UnauthorizedErrors);

            var prize = await _unitOfWork.Prizes.GetByIdAsync(prizeId);
            if (prize == null)
                return ApiResponse<PrizeDetailDto>.FailureResponse("الجائزة غير موجودة", new List<string> { "الجائزة غير موجودة" });

            var child = await _unitOfWork.Children.GetByIdAsync(prize.ChildId);
            if (child == null || child.ParentId != parent.Id || prize.ParentId != parent.Id)
                return ApiResponse<PrizeDetailDto>.FailureResponse("الجائزة غير موجودة", new List<string> { "الجائزة غير موجودة" });

            return ApiResponse<PrizeDetailDto>.SuccessResponse(await BuildDetailDtoAsync(prize), "تم جلب الجائزة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<PrizeDetailDto>.FailureResponse("حدث خطأ أثناء جلب الجائزة", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<PrizeDetailDto>> UpdatePrizeAsync(Guid prizeId, UpdatePrizeRequestDto request, Guid requestingUserId)
    {
        try
        {
            var parent = await GetParentAsync(requestingUserId);
            if (parent == null)
                return ApiResponse<PrizeDetailDto>.FailureResponse("غير مصرح", UnauthorizedErrors);

            var prize = await _unitOfWork.Prizes.GetByIdAsync(prizeId);
            if (prize == null)
                return ApiResponse<PrizeDetailDto>.FailureResponse("الجائزة غير موجودة", new List<string> { "الجائزة غير موجودة" });

            var child = await _unitOfWork.Children.GetByIdAsync(prize.ChildId);
            if (child == null || child.ParentId != parent.Id || prize.ParentId != parent.Id)
                return ApiResponse<PrizeDetailDto>.FailureResponse("الجائزة غير موجودة", new List<string> { "الجائزة غير موجودة" });

            if (prize.Status == PrizeStatus.Delivered)
                return ApiResponse<PrizeDetailDto>.FailureResponse("تم تسليم الجائزة بالفعل — لا يمكن التعديل",
                    new List<string> { "تم تسليم الجائزة بالفعل — لا يمكن التعديل" });

            int? parsedRequiredStars = null;
            if (!string.IsNullOrWhiteSpace(request.RequiredStars))
            {
                if (!int.TryParse(request.RequiredStars, out var stars) || stars <= 0)
                    return ApiResponse<PrizeDetailDto>.FailureResponse("عدد النجوم المطلوبة يجب أن يكون أكبر من صفر",
                        new List<string> { "عدد النجوم المطلوبة يجب أن يكون أكبر من صفر" });

                parsedRequiredStars = stars;
            }

            var newTaskIds = request.TaskIds?
                .Where(s => !string.IsNullOrWhiteSpace(s))
                .Select(s => Guid.TryParse(s, out var taskId) ? taskId : Guid.Empty)
                .Where(id => id != Guid.Empty)
                .Distinct()
                .ToList();

            if (request.TaskIds != null)
            {
                if (newTaskIds == null || newTaskIds.Count == 0)
                    return ApiResponse<PrizeDetailDto>.FailureResponse("يجب اختيار مهمة واحدة على الأقل",
                        new List<string> { "يجب اختيار مهمة واحدة على الأقل" });

                if (newTaskIds.Count != request.TaskIds.Where(s => !string.IsNullOrWhiteSpace(s)).Distinct().Count())
                    return ApiResponse<PrizeDetailDto>.FailureResponse("المهمة المحددة غير موجودة أو لا تخص هذا الطفل",
                        new List<string> { "المهمة المحددة غير موجودة أو لا تخص هذا الطفل" });

                if (!await ValidateTasksBelongToChildAsync(newTaskIds, prize.ChildId, parent.Id))
                    return ApiResponse<PrizeDetailDto>.FailureResponse("المهمة المحددة غير موجودة أو لا تخص هذا الطفل",
                        new List<string> { "المهمة المحددة غير موجودة أو لا تخص هذا الطفل" });
            }

            string? finalImageUrl = prize.ImageUrl;
            if (request.PrizeImage != null && request.PrizeImage.Length > 0)
            {
                if (!string.IsNullOrEmpty(prize.ImageUrl)) await _imageService.DeleteBlobByUrlAsync(prize.ImageUrl);
                try { finalImageUrl = await _imageService.UploadPrizeImageAsync(request.PrizeImage, requestingUserId); }
                catch (ArgumentException ex)
                {
                    return ApiResponse<PrizeDetailDto>.FailureResponse("خطأ في ملف الصورة", new List<string> { ex.Message });
                }
            }
            else if (request.ExistingImageUrl != null)
            {
                if (string.IsNullOrEmpty(request.ExistingImageUrl))
                {
                    if (!string.IsNullOrEmpty(prize.ImageUrl)) await _imageService.DeleteBlobByUrlAsync(prize.ImageUrl);
                    finalImageUrl = null;
                }
                else
                {
                    finalImageUrl = request.ExistingImageUrl;
                }
            }

            if (!string.IsNullOrWhiteSpace(request.Title)) prize.Title = request.Title.Trim();
            if (parsedRequiredStars.HasValue) prize.RequiredStars = parsedRequiredStars.Value;
            prize.ImageUrl = finalImageUrl;
            prize.UpdatedAt = DateTime.Now;

            await _unitOfWork.Prizes.UpdateAsync(prize);

            if (newTaskIds != null && newTaskIds.Count > 0)
            {
                var existingPrizeTasks = (await _unitOfWork.PrizeTasks.FindAsync(pt => pt.PrizeId == prize.Id)).ToList();
                foreach (var prizeTask in existingPrizeTasks)
                    await _unitOfWork.PrizeTasks.DeleteAsync(prizeTask);

                foreach (var taskId in newTaskIds)
                    await _unitOfWork.PrizeTasks.AddAsync(new PrizeTask { PrizeId = prize.Id, TaskId = taskId });
            }

            await _unitOfWork.SaveChangesAsync();
            return ApiResponse<PrizeDetailDto>.SuccessResponse(await BuildDetailDtoAsync(prize), "تم تحديث الجائزة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<PrizeDetailDto>.FailureResponse("حدث خطأ أثناء تحديث الجائزة", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<bool>> DeletePrizeAsync(Guid prizeId, Guid requestingUserId)
    {
        try
        {
            var parent = await GetParentAsync(requestingUserId);
            if (parent == null)
                return ApiResponse<bool>.FailureResponse("غير مصرح", UnauthorizedErrors);

            var prize = await _unitOfWork.Prizes.GetByIdAsync(prizeId);
            if (prize == null)
                return ApiResponse<bool>.FailureResponse("الجائزة غير موجودة", new List<string> { "الجائزة غير موجودة" });

            var child = await _unitOfWork.Children.GetByIdAsync(prize.ChildId);
            if (child == null || child.ParentId != parent.Id || prize.ParentId != parent.Id)
                return ApiResponse<bool>.FailureResponse("الجائزة غير موجودة", new List<string> { "الجائزة غير موجودة" });

            if (!string.IsNullOrEmpty(prize.ImageUrl))
                await _imageService.DeleteBlobByUrlAsync(prize.ImageUrl);

            var prizeTasks = (await _unitOfWork.PrizeTasks.FindAsync(pt => pt.PrizeId == prize.Id)).ToList();
            foreach (var prizeTask in prizeTasks)
                await _unitOfWork.PrizeTasks.DeleteAsync(prizeTask);

            await _unitOfWork.Prizes.DeleteAsync(prize);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.SuccessResponse(true, "تم حذف الجائزة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<bool>.FailureResponse("حدث خطأ أثناء حذف الجائزة", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<PrizeDetailDto>> DeliverPrizeAsync(Guid prizeId, Guid requestingUserId)
    {
        try
        {
            var parent = await GetParentAsync(requestingUserId);
            if (parent == null)
                return ApiResponse<PrizeDetailDto>.FailureResponse("غير مصرح", UnauthorizedErrors);

            var prize = await _unitOfWork.Prizes.GetByIdAsync(prizeId);
            if (prize == null)
                return ApiResponse<PrizeDetailDto>.FailureResponse("الجائزة غير موجودة", new List<string> { "الجائزة غير موجودة" });

            var child = await _unitOfWork.Children.GetByIdAsync(prize.ChildId);
            if (child == null || child.ParentId != parent.Id || prize.ParentId != parent.Id)
                return ApiResponse<PrizeDetailDto>.FailureResponse("الجائزة غير موجودة", new List<string> { "الجائزة غير موجودة" });

            if (!child.IsActive)
                return ApiResponse<PrizeDetailDto>.FailureResponse("حساب الطفل غير مفعل",
                    new List<string> { "حساب الطفل غير مفعل" });

            if (prize.Status == PrizeStatus.Delivered)
                return ApiResponse<PrizeDetailDto>.FailureResponse("تم تسليم الجائزة بالفعل — لا يمكن التعديل",
                    new List<string> { "تم تسليم الجائزة بالفعل — لا يمكن التعديل" });

            var progress = await GetProgressAsync(prize);
            if (progress.completedTasksCount != progress.totalRequiredTasks)
                return ApiResponse<PrizeDetailDto>.FailureResponse("لا يمكن تسليم الجائزة — لم يتم إكمال جميع المهام المطلوبة",
                    new List<string> { "لا يمكن تسليم الجائزة — لم يتم إكمال جميع المهام المطلوبة" });

            if (progress.currentStars < prize.RequiredStars)
                return ApiResponse<PrizeDetailDto>.FailureResponse("لا يمكن تسليم الجائزة — النجوم غير كافية",
                    new List<string> { "لا يمكن تسليم الجائزة — النجوم غير كافية" });

            prize.Status = PrizeStatus.Delivered;
            prize.DeliveredAt = DateTime.Now;
            prize.UpdatedAt = DateTime.Now;

            await _unitOfWork.Prizes.UpdateAsync(prize);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<PrizeDetailDto>.SuccessResponse(await BuildDetailDtoAsync(prize), "تم تسليم الجائزة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<PrizeDetailDto>.FailureResponse("حدث خطأ أثناء تسليم الجائزة", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<GetPrizesForParentResponseDto>> GetPrizesForParentAsync(Guid parentId, Guid requestingUserId)
    {
        try
        {
            var parent = await GetParentAsync(requestingUserId);
            if (parent == null || parent.Id != parentId)
                return ApiResponse<GetPrizesForParentResponseDto>.FailureResponse("غير مصرح", UnauthorizedErrors);

            var prizes = (await _unitOfWork.Prizes.FindAsync(p => p.ParentId == parent.Id))
                .OrderByDescending(p => p.CreatedAt)
                .ToList();

            var prizeDetails = new List<PrizeDetailDto>();
            foreach (var prize in prizes)
                prizeDetails.Add(await BuildDetailDtoAsync(prize));

            return ApiResponse<GetPrizesForParentResponseDto>.SuccessResponse(new GetPrizesForParentResponseDto
            {
                ParentId = parent.Id,
                TotalPrizes = prizeDetails.Count,
                Prizes = prizeDetails
            }, "تم جلب الجوائز بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<GetPrizesForParentResponseDto>.FailureResponse("حدث خطأ أثناء جلب الجوائز", new List<string> { ex.Message });
        }
    }
}
