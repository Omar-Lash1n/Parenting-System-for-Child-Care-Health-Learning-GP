using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Home;
using Ajial.Application.DTOs.Task;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Service;

public class ParentHomeService : IParentHomeService
{
    private readonly IUnitOfWork _unitOfWork;

    public ParentHomeService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    // A) Current Vaccinations

    public async Task<ApiResponse<GetCurrentVaccinationsResponseDto>>
        GetCurrentVaccinationsAsync(Guid parentUserId)
    {
        try
        {
            // 1. Validate parent
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(
                p => p.UserId == parentUserId);
            if (parent == null)
                return ApiResponse<GetCurrentVaccinationsResponseDto>.FailureResponse(
                    "ولي الأمر غير موجود",
                    new List<string> { "لم يتم العثور على حساب ولي الأمر" });

            // 2. Load parent's active children
            var children = (await _unitOfWork.Children.FindAsync(
                c => c.ParentId == parent.Id && c.IsActive)).ToList();

            if (!children.Any())
            {
                return ApiResponse<GetCurrentVaccinationsResponseDto>.SuccessResponse(
                    new GetCurrentVaccinationsResponseDto(),
                    "يبدو أنه لا يوجد تطعيم في الوقت الحالي");
            }

            // 3. Load all active Main milestones
            var milestones = (await _unitOfWork.VaccinationMilestones.FindAsync(
                m => m.IsActive && m.Category == "Main"))
                .OrderBy(m => m.SortOrder).ToList();

            var cards = new List<CurrentVaccinationCardDto>();

            foreach (var child in children)
            {
                // 4. Calculate child's age in months
                var (ageMonths, _) = CalculateAgeInMonthsAndDays(child.BirthDate);

                // 5. Find the "current" milestone (AgeInMonths == childAgeMonths)
                var currentMilestone = milestones
                    .FirstOrDefault(m => m.AgeInMonths == ageMonths);

                if (currentMilestone == null) continue;

                // 6. Check if already taken
                var vaccination = await _unitOfWork.ChildVaccinations
                    .GetFirstOrDefaultAsync(cv =>
                        cv.ChildId == child.Id &&
                        cv.VaccinationMilestoneId == currentMilestone.Id);

                if (vaccination != null && vaccination.IsTaken) continue;

                // 7. Look up appointment/reminder data
                var appointment = await _unitOfWork.VaccinationAppointments
                    .GetFirstOrDefaultAsync(va =>
                        va.ChildId == child.Id &&
                        va.VaccinationMilestoneId == currentMilestone.Id);

                bool isReminderEnabled = appointment != null &&
                    (appointment.NotifyOneDayBefore ||
                     appointment.NotifyThreeHoursBefore ||
                     appointment.CustomReminderEnabled);

                DateTime? reminderDateTime = appointment?.AppointmentDateTime;

                // 8. Build card
                cards.Add(new CurrentVaccinationCardDto
                {
                    ChildId = child.Id,
                    ChildName = child.FullName.Split(' ')[0],
                    ChildImageUrl = child.ProfileImageUrl,
                    VaccinationMilestoneId = currentMilestone.Id,
                    Title = currentMilestone.NameAr,
                    Description = currentMilestone.VaccinesAr,
                    DueDate = child.BirthDate.AddMonths(currentMilestone.AgeInMonths),
                    AgeLabel = FormatMilestoneAgeLabel(currentMilestone.AgeInMonths),
                    Status = "current",
                    IsReminderEnabled = isReminderEnabled,
                    ReminderDateTime = reminderDateTime
                });
            }

            var message = cards.Any()
                ? "تم جلب التطعيمات الحالية بنجاح"
                : "يبدو أنه لا يوجد تطعيم في الوقت الحالي";

            return ApiResponse<GetCurrentVaccinationsResponseDto>.SuccessResponse(
                new GetCurrentVaccinationsResponseDto { Vaccinations = cards },
                message);
        }
        catch (Exception ex)
        {
            return ApiResponse<GetCurrentVaccinationsResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب التطعيمات الحالية",
                new List<string> { ex.Message });
        }
    }

    // B) Upcoming Tasks

    public async Task<ApiResponse<GetUpcomingTasksResponseDto>>
        GetUpcomingTasksAsync(Guid parentUserId, int limit = 5)
    {
        try
        {
            // 1. Clamp limit
            limit = Math.Clamp(limit, 1, 10);

            // 2. Validate parent
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(
                p => p.UserId == parentUserId);
            if (parent == null)
                return ApiResponse<GetUpcomingTasksResponseDto>.FailureResponse(
                    "ولي الأمر غير موجود",
                    new List<string> { "لم يتم العثور على حساب ولي الأمر" });

            // 3. Query upcoming incomplete tasks
            var today = DateTime.Today;
            var tasks = (await _unitOfWork.Tasks.FindAsync(
                t => t.ParentId == parent.Id &&
                     !t.IsCompleted &&
                     t.DueDate.HasValue &&
                     t.DueDate.Value.Date >= today))
                .OrderBy(t => t.DueDate)
                .Take(limit)
                .ToList();

            if (!tasks.Any())
            {
                return ApiResponse<GetUpcomingTasksResponseDto>.SuccessResponse(
                    new GetUpcomingTasksResponseDto(),
                    "يبدو أنه لا يوجد مهام في الوقت الحالي");
            }

            // 4. Preload lookup data for assignees
            var parentUser = await _unitOfWork.Users.GetByIdAsync(parent.UserId);
            var childrenDict = (await _unitOfWork.Children
                .FindAsync(c => c.ParentId == parent.Id))
                .ToDictionary(c => c.Id);
            var categoriesDict = (await _unitOfWork.TaskCategories
                .FindAsync(tc => tc.ParentId == parent.Id))
                .ToDictionary(tc => tc.Id);
            var systemCategory = await _unitOfWork.TaskCategories
                .GetFirstOrDefaultAsync(tc => tc.ParentId == parent.Id && tc.IsSystem);

            // 5. Build task cards (reusing existing TaskCardDto pattern)
            var taskCards = new List<TaskCardDto>();

            foreach (var task in tasks)
            {
                // Resolve category
                TaskCategoryDto categoryDto;
                if (task.CategoryId.HasValue &&
                    categoriesDict.TryGetValue(task.CategoryId.Value, out var cat))
                {
                    categoryDto = new TaskCategoryDto { Id = cat.Id, Name = cat.Name };
                }
                else if (systemCategory != null)
                {
                    categoryDto = new TaskCategoryDto
                        { Id = systemCategory.Id, Name = systemCategory.Name };
                }
                else
                {
                    categoryDto = new TaskCategoryDto { Id = Guid.Empty, Name = "الكل" };
                }

                // Build assignees
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

                var taskAssignees = (await _unitOfWork.TaskAssignees
                    .FindAsync(ta => ta.TaskId == task.Id)).ToList();
                foreach (var ta in taskAssignees)
                {
                    if (childrenDict.TryGetValue(ta.ChildId, out var child))
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

            return ApiResponse<GetUpcomingTasksResponseDto>.SuccessResponse(
                new GetUpcomingTasksResponseDto { Tasks = taskCards },
                "تم جلب المهام القادمة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<GetUpcomingTasksResponseDto>.FailureResponse(
                "حدث خطأ أثناء جلب المهام القادمة",
                new List<string> { ex.Message });
        }
    }

    // Private Helpers

    private static (int months, int days) CalculateAgeInMonthsAndDays(DateTime birthDate)
    {
        // EXACT copy from VaccinationService.cs:283-298
        var today = DateTime.UtcNow.Date;
        var birth = birthDate.Date;
        int months = (today.Year - birth.Year) * 12 + (today.Month - birth.Month);
        int days = today.Day - birth.Day;
        if (days < 0)
        {
            months--;
            var previousMonth = today.AddMonths(-1);
            days += DateTime.DaysInMonth(previousMonth.Year, previousMonth.Month);
        }
        return (Math.Max(0, months), Math.Max(0, days));
    }

    private static string FormatMilestoneAgeLabel(int ageInMonths) => ageInMonths switch
    {
        0 => "الولادة",
        2 => "شهرين",
        4 => "4 شهور",
        6 => "6 شهور",
        9 => "9 شهور",
        12 => "12 شهر",
        18 => "18 شهر",
        _ => $"{ageInMonths} شهر"
    };
}
