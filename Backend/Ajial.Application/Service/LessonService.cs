using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Lesson;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;
using Microsoft.EntityFrameworkCore;
using LessonEntity = Ajial.Domain.Entities.Lesson;
using LessonQuestionEntity = Ajial.Domain.Entities.LessonQuestion;
using LessonQuestionOptionEntity = Ajial.Domain.Entities.LessonQuestionOption;

namespace Ajial.Application.Service;

public class LessonService : ILessonService
{
    private const string ServerErrorMessage = "حدث خطأ في الخادم";
    private const string LessonNotFoundMessage = "الدرس غير موجود";
    private const string CategoryNotFoundMessage = "التصنيف غير موجود";
    private const string QuestionNotFoundMessage = "السؤال غير موجود";
    private const string NotReadYetMessage = "يجب قراءة الدرس أولاً للوصول إلى الأسئلة";
    private const string AlreadyAnsweredMessage = "لقد أجبت على هذا السؤال مسبقاً";
    private const string InvalidOptionMessage = "الخيار غير صالح لهذا السؤال";
    private const string InvalidDataMessage = "بيانات غير صحيحة";

    private readonly IUnitOfWork _unitOfWork;

    public LessonService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    // ─── Admin: Categories ────────────────────────────────────────────────────

    public async Task<ApiResponse<LessonCategoryDto>> CreateCategoryAsync(CreateLessonCategoryDto dto)
    {
        var errors = ValidateCategory(dto.NameAr);
        if (errors.Count > 0)
            return ApiResponse<LessonCategoryDto>.FailureResponse(InvalidDataMessage, errors);

        try
        {
            var category = new LessonCategory
            {
                Id = Guid.NewGuid(),
                NameAr = dto.NameAr.Trim(),
                NameEn = dto.NameEn?.Trim(),
                OrderIndex = dto.OrderIndex,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.LessonCategories.AddAsync(category);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<LessonCategoryDto>.SuccessResponse(MapCategoryDto(category, 0), "تم إنشاء التصنيف بنجاح");
        }
        catch
        {
            return ApiResponse<LessonCategoryDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<List<LessonCategoryDto>>> GetCategoriesAsync(bool? isActive)
    {
        try
        {
            var categories = await _unitOfWork.LessonCategories.GetAllAsync(query =>
                query.Include(c => c.Lessons).OrderBy(c => c.OrderIndex));

            if (isActive.HasValue)
                categories = categories.Where(c => c.IsActive == isActive.Value).ToList();

            var result = categories
                .Select(c => MapCategoryDto(c, c.Lessons.Count(l => l.IsActive)))
                .ToList();

            return ApiResponse<List<LessonCategoryDto>>.SuccessResponse(result);
        }
        catch
        {
            return ApiResponse<List<LessonCategoryDto>>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<LessonCategoryDto>> UpdateCategoryAsync(Guid categoryId, UpdateLessonCategoryDto dto)
    {
        var errors = ValidateCategory(dto.NameAr);
        if (errors.Count > 0)
            return ApiResponse<LessonCategoryDto>.FailureResponse(InvalidDataMessage, errors);

        try
        {
            var category = await _unitOfWork.LessonCategories.GetFirstOrDefaultAsync(c => c.Id == categoryId, "Lessons");
            if (category == null)
                return ApiResponse<LessonCategoryDto>.FailureResponse(CategoryNotFoundMessage, new List<string> { CategoryNotFoundMessage });

            category.NameAr = dto.NameAr.Trim();
            category.NameEn = dto.NameEn?.Trim();
            category.OrderIndex = dto.OrderIndex;
            category.IsActive = dto.IsActive;

            await _unitOfWork.LessonCategories.UpdateAsync(category);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<LessonCategoryDto>.SuccessResponse(
                MapCategoryDto(category, category.Lessons.Count(l => l.IsActive)), "تم تحديث التصنيف بنجاح");
        }
        catch
        {
            return ApiResponse<LessonCategoryDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<bool>> DeleteCategoryAsync(Guid categoryId)
    {
        try
        {
            var category = await _unitOfWork.LessonCategories.GetFirstOrDefaultAsync(c => c.Id == categoryId, "Lessons");
            if (category == null)
                return ApiResponse<bool>.FailureResponse(CategoryNotFoundMessage, new List<string> { CategoryNotFoundMessage });

            if (category.Lessons.Any())
                return ApiResponse<bool>.FailureResponse("لا يمكن حذف تصنيف يحتوي على دروس", new List<string> { "لا يمكن حذف تصنيف يحتوي على دروس" });

            await _unitOfWork.LessonCategories.DeleteAsync(category);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.SuccessResponse(true, "تم حذف التصنيف بنجاح");
        }
        catch
        {
            return ApiResponse<bool>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    // ─── Admin: Lessons ───────────────────────────────────────────────────────

    public async Task<ApiResponse<LessonAdminDetailDto>> CreateLessonAsync(CreateLessonDto dto, Guid adminUserId)
    {
        var errors = ValidateLesson(dto.TitleAr, dto.ContentAr, dto.Questions);
        if (errors.Count > 0)
            return ApiResponse<LessonAdminDetailDto>.FailureResponse(InvalidDataMessage, errors);

        try
        {
            var category = await _unitOfWork.LessonCategories.GetByIdAsync(dto.CategoryId);
            if (category == null)
                return ApiResponse<LessonAdminDetailDto>.FailureResponse(CategoryNotFoundMessage, new List<string> { CategoryNotFoundMessage });

            var lesson = new LessonEntity
            {
                Id = Guid.NewGuid(),
                CategoryId = dto.CategoryId,
                TitleAr = dto.TitleAr.Trim(),
                ContentAr = dto.ContentAr.Trim(),
                ImageUrl = dto.ImageUrl?.Trim(),
                VideoUrl = dto.VideoUrl?.Trim(),
                IsActive = dto.IsActive,
                CreatedByAdminId = adminUserId,
                CreatedAt = DateTime.UtcNow,
                Questions = BuildQuestions(dto.Questions)
            };

            await _unitOfWork.Lessons.AddAsync(lesson);
            await _unitOfWork.SaveChangesAsync();

            var created = await GetLessonWithFullDetailsAsync(lesson.Id);
            return ApiResponse<LessonAdminDetailDto>.SuccessResponse(MapAdminDetailDto(created!, category.NameAr), "تم إنشاء الدرس بنجاح");
        }
        catch
        {
            return ApiResponse<LessonAdminDetailDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<List<LessonAdminListDto>>> GetAllLessonsAdminAsync(Guid? categoryId, bool? isActive)
    {
        try
        {
            var lessons = await _unitOfWork.Lessons.GetAllAsync(query =>
                query
                    .Include(l => l.Category)
                    .Include(l => l.Questions)
                    .Include(l => l.Progresses)
                    .OrderByDescending(l => l.CreatedAt));

            if (categoryId.HasValue)
                lessons = lessons.Where(l => l.CategoryId == categoryId.Value).ToList();

            if (isActive.HasValue)
                lessons = lessons.Where(l => l.IsActive == isActive.Value).ToList();

            var result = lessons.Select(l => new LessonAdminListDto
            {
                Id = l.Id,
                TitleAr = l.TitleAr,
                ImageUrl = l.ImageUrl,
                CategoryNameAr = l.Category.NameAr,
                IsActive = l.IsActive,
                QuestionsCount = l.Questions.Count,
                TotalStarsReward = l.Questions.Sum(q => q.StarsReward),
                TotalReads = l.Progresses.Count(p => p.IsRead),
                TotalCompletions = l.Progresses.Count(p => p.IsQuizCompleted),
                CreatedAt = l.CreatedAt
            }).ToList();

            return ApiResponse<List<LessonAdminListDto>>.SuccessResponse(result);
        }
        catch
        {
            return ApiResponse<List<LessonAdminListDto>>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<LessonAdminDetailDto>> GetLessonByIdAdminAsync(Guid lessonId)
    {
        try
        {
            var lesson = await GetLessonWithFullDetailsAsync(lessonId);
            if (lesson == null)
                return ApiResponse<LessonAdminDetailDto>.FailureResponse(LessonNotFoundMessage, new List<string> { LessonNotFoundMessage });

            return ApiResponse<LessonAdminDetailDto>.SuccessResponse(MapAdminDetailDto(lesson, lesson.Category.NameAr));
        }
        catch
        {
            return ApiResponse<LessonAdminDetailDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<LessonAdminDetailDto>> UpdateLessonAsync(Guid lessonId, UpdateLessonDto dto)
    {
        var errors = ValidateLesson(dto.TitleAr, dto.ContentAr, dto.Questions);
        if (errors.Count > 0)
            return ApiResponse<LessonAdminDetailDto>.FailureResponse(InvalidDataMessage, errors);

        try
        {
            var lesson = await GetLessonWithFullDetailsAsync(lessonId);
            if (lesson == null)
                return ApiResponse<LessonAdminDetailDto>.FailureResponse(LessonNotFoundMessage, new List<string> { LessonNotFoundMessage });

            if (lesson.Progresses.Any(p => p.IsQuizCompleted))
                return ApiResponse<LessonAdminDetailDto>.FailureResponse(
                    "لا يمكن تعديل درس تمت الإجابة على أسئلته",
                    new List<string> { "لا يمكن تعديل درس تمت الإجابة على أسئلته" });

            var category = await _unitOfWork.LessonCategories.GetByIdAsync(dto.CategoryId);
            if (category == null)
                return ApiResponse<LessonAdminDetailDto>.FailureResponse(CategoryNotFoundMessage, new List<string> { CategoryNotFoundMessage });

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                foreach (var q in lesson.Questions.ToList())
                {
                    foreach (var o in q.Options.ToList())
                        await _unitOfWork.LessonQuestionOptions.DeleteAsync(o);
                    await _unitOfWork.LessonQuestions.DeleteAsync(q);
                }

                lesson.CategoryId = dto.CategoryId;
                lesson.TitleAr = dto.TitleAr.Trim();
                lesson.ContentAr = dto.ContentAr.Trim();
                lesson.ImageUrl = dto.ImageUrl?.Trim();
                lesson.VideoUrl = dto.VideoUrl?.Trim();
                lesson.UpdatedAt = DateTime.UtcNow;
                lesson.Questions = BuildQuestions(dto.Questions);

                await _unitOfWork.Lessons.UpdateAsync(lesson);
            });

            var updated = await GetLessonWithFullDetailsAsync(lessonId);
            return ApiResponse<LessonAdminDetailDto>.SuccessResponse(MapAdminDetailDto(updated!, category.NameAr), "تم تحديث الدرس بنجاح");
        }
        catch
        {
            return ApiResponse<LessonAdminDetailDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<bool>> DeleteLessonAsync(Guid lessonId)
    {
        try
        {
            var lesson = await GetLessonWithFullDetailsAsync(lessonId);
            if (lesson == null)
                return ApiResponse<bool>.FailureResponse(LessonNotFoundMessage, new List<string> { LessonNotFoundMessage });

            if (lesson.Progresses.Any(p => p.IsQuizCompleted))
                return ApiResponse<bool>.FailureResponse(
                    "لا يمكن حذف درس تمت الإجابة على أسئلته",
                    new List<string> { "لا يمكن حذف درس تمت الإجابة على أسئلته" });

            await _unitOfWork.Lessons.DeleteAsync(lesson);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.SuccessResponse(true, "تم حذف الدرس بنجاح");
        }
        catch
        {
            return ApiResponse<bool>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<LessonAdminDetailDto>> ActivateLessonAsync(Guid lessonId)
    {
        try
        {
            var lesson = await GetLessonWithFullDetailsAsync(lessonId);
            if (lesson == null)
                return ApiResponse<LessonAdminDetailDto>.FailureResponse(LessonNotFoundMessage, new List<string> { LessonNotFoundMessage });

            lesson.IsActive = true;
            lesson.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Lessons.UpdateAsync(lesson);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<LessonAdminDetailDto>.SuccessResponse(MapAdminDetailDto(lesson, lesson.Category.NameAr), "تم تفعيل الدرس بنجاح");
        }
        catch
        {
            return ApiResponse<LessonAdminDetailDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<LessonAdminDetailDto>> DeactivateLessonAsync(Guid lessonId)
    {
        try
        {
            var lesson = await GetLessonWithFullDetailsAsync(lessonId);
            if (lesson == null)
                return ApiResponse<LessonAdminDetailDto>.FailureResponse(LessonNotFoundMessage, new List<string> { LessonNotFoundMessage });

            lesson.IsActive = false;
            lesson.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Lessons.UpdateAsync(lesson);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<LessonAdminDetailDto>.SuccessResponse(MapAdminDetailDto(lesson, lesson.Category.NameAr), "تم إلغاء تفعيل الدرس بنجاح");
        }
        catch
        {
            return ApiResponse<LessonAdminDetailDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    // ─── Parent ───────────────────────────────────────────────────────────────

    public async Task<ApiResponse<List<LessonCategoryDto>>> GetActiveCategoriesAsync()
    {
        try
        {
            var categories = await _unitOfWork.LessonCategories.GetAllAsync(query =>
                query.Where(c => c.IsActive)
                     .Include(c => c.Lessons)
                     .OrderBy(c => c.OrderIndex));

            var result = categories
                .Select(c => MapCategoryDto(c, c.Lessons.Count(l => l.IsActive)))
                .ToList();

            return ApiResponse<List<LessonCategoryDto>>.SuccessResponse(result);
        }
        catch
        {
            return ApiResponse<List<LessonCategoryDto>>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<List<LessonCardDto>>> GetLessonsForParentAsync(GetLessonsQueryDto query, Guid parentId)
    {
        try
        {
            var lessons = await _unitOfWork.Lessons.GetAllAsync(q =>
                q.Where(l => l.IsActive)
                 .Include(l => l.Category)
                 .Include(l => l.Questions)
                 .Include(l => l.Progresses.Where(p => p.ParentId == parentId))
                 .OrderByDescending(l => l.CreatedAt));

            if (query.CategoryId.HasValue)
                lessons = lessons.Where(l => l.CategoryId == query.CategoryId.Value).ToList();

            if (!string.IsNullOrWhiteSpace(query.Search))
            {
                var term = query.Search.Trim();
                lessons = lessons
                    .Where(l => l.TitleAr.Contains(term, StringComparison.OrdinalIgnoreCase)
                             || l.ContentAr.Contains(term, StringComparison.OrdinalIgnoreCase))
                    .ToList();
            }

            var paged = lessons
                .Skip((query.Page - 1) * query.PageSize)
                .Take(query.PageSize)
                .ToList();

            var result = paged.Select(l =>
            {
                var progress = l.Progresses.FirstOrDefault();
                var totalStars = l.Questions.Sum(q => q.StarsReward);
                return new LessonCardDto
                {
                    Id = l.Id,
                    TitleAr = l.TitleAr,
                    ContentPreviewAr = l.ContentAr.Length > 100 ? l.ContentAr[..100] + "..." : l.ContentAr,
                    ImageUrl = l.ImageUrl,
                    CategoryNameAr = l.Category.NameAr,
                    CategoryId = l.CategoryId,
                    TotalStarsReward = totalStars,
                    QuestionsCount = l.Questions.Count,
                    IsRead = progress?.IsRead ?? false,
                    IsQuizCompleted = progress?.IsQuizCompleted ?? false,
                    StarsEarned = progress?.TotalStarsEarned ?? 0
                };
            }).ToList();

            return ApiResponse<List<LessonCardDto>>.SuccessResponse(result);
        }
        catch
        {
            return ApiResponse<List<LessonCardDto>>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<LessonDetailDto>> GetLessonDetailForParentAsync(Guid lessonId, Guid parentId)
    {
        try
        {
            var lesson = await _unitOfWork.Lessons.GetFirstOrDefaultAsync(
                l => l.Id == lessonId && l.IsActive,
                "Category,Questions,Progresses");

            if (lesson == null)
                return ApiResponse<LessonDetailDto>.FailureResponse(LessonNotFoundMessage, new List<string> { LessonNotFoundMessage });

            var progress = lesson.Progresses.FirstOrDefault(p => p.ParentId == parentId);
            var totalStars = lesson.Questions.Sum(q => q.StarsReward);

            return ApiResponse<LessonDetailDto>.SuccessResponse(new LessonDetailDto
            {
                Id = lesson.Id,
                TitleAr = lesson.TitleAr,
                ContentAr = lesson.ContentAr,
                ImageUrl = lesson.ImageUrl,
                VideoUrl = lesson.VideoUrl,
                CategoryId = lesson.CategoryId,
                CategoryNameAr = lesson.Category.NameAr,
                TotalStarsReward = totalStars,
                QuestionsCount = lesson.Questions.Count,
                IsRead = progress?.IsRead ?? false,
                IsQuizCompleted = progress?.IsQuizCompleted ?? false,
                StarsEarned = progress?.TotalStarsEarned ?? 0
            });
        }
        catch
        {
            return ApiResponse<LessonDetailDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<MarkLessonReadResponseDto>> MarkLessonReadAsync(Guid lessonId, Guid parentId)
    {
        try
        {
            var lesson = await _unitOfWork.Lessons.GetFirstOrDefaultAsync(
                l => l.Id == lessonId && l.IsActive,
                "Questions,Questions.Options,Questions.Answers,Progresses");

            if (lesson == null)
                return ApiResponse<MarkLessonReadResponseDto>.FailureResponse(LessonNotFoundMessage, new List<string> { LessonNotFoundMessage });

            var progress = lesson.Progresses.FirstOrDefault(p => p.ParentId == parentId);

            if (progress == null)
            {
                progress = new LessonProgress
                {
                    Id = Guid.NewGuid(),
                    ParentId = parentId,
                    LessonId = lessonId,
                    IsRead = true,
                    ReadAt = DateTime.UtcNow
                };
                await _unitOfWork.LessonProgresses.AddAsync(progress);
                await _unitOfWork.SaveChangesAsync();
            }
            else if (!progress.IsRead)
            {
                progress.IsRead = true;
                progress.ReadAt = DateTime.UtcNow;
                await _unitOfWork.LessonProgresses.UpdateAsync(progress);
                await _unitOfWork.SaveChangesAsync();
            }

            var parentAnswers = await _unitOfWork.LessonQuestionAnswers.FindAsync(
                a => a.ParentId == parentId && lesson.Questions.Select(q => q.Id).Contains(a.LessonQuestionId));

            var questions = lesson.Questions.OrderBy(q => q.OrderIndex).Select(q =>
            {
                var answer = parentAnswers.FirstOrDefault(a => a.LessonQuestionId == q.Id);
                var correctOptionId = q.Options.First(o => o.IsCorrect).Id;
                return new LessonQuizQuestionDto
                {
                    Id = q.Id,
                    QuestionText = q.QuestionText,
                    StarsReward = q.StarsReward,
                    OrderIndex = q.OrderIndex,
                    Options = q.Options.OrderBy(o => o.OrderIndex).Select(o => new LessonQuizOptionDto
                    {
                        Id = o.Id,
                        OptionText = o.OptionText,
                        OrderIndex = o.OrderIndex
                    }).ToList(),
                    HasAnswered = answer != null,
                    PreviousAnswer = answer == null ? null : new LessonPreviousAnswerDto
                    {
                        SelectedOptionId = answer.SelectedOptionId,
                        IsCorrect = answer.IsCorrect,
                        StarsEarned = answer.StarsEarned,
                        CorrectOptionId = correctOptionId
                    }
                };
            }).ToList();

            return ApiResponse<MarkLessonReadResponseDto>.SuccessResponse(new MarkLessonReadResponseDto
            {
                IsRead = true,
                Questions = questions
            }, "تم تسجيل قراءة الدرس بنجاح");
        }
        catch
        {
            return ApiResponse<MarkLessonReadResponseDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<LessonAnswerResultDto>> SubmitAnswerAsync(
        Guid lessonId, Guid questionId, SubmitLessonAnswerDto dto, Guid parentId)
    {
        if (dto.SelectedOptionId == Guid.Empty)
            return ApiResponse<LessonAnswerResultDto>.FailureResponse("لم يتم اختيار إجابة", new List<string> { "لم يتم اختيار إجابة" });

        try
        {
            var progress = await _unitOfWork.LessonProgresses.GetFirstOrDefaultAsync(
                p => p.ParentId == parentId && p.LessonId == lessonId);

            if (progress == null || !progress.IsRead)
                return ApiResponse<LessonAnswerResultDto>.FailureResponse(NotReadYetMessage, new List<string> { NotReadYetMessage });

            var question = await _unitOfWork.LessonQuestions.GetFirstOrDefaultAsync(
                q => q.Id == questionId && q.LessonId == lessonId, "Options");

            if (question == null)
                return ApiResponse<LessonAnswerResultDto>.FailureResponse(QuestionNotFoundMessage, new List<string> { QuestionNotFoundMessage });

            var selectedOption = question.Options.FirstOrDefault(o => o.Id == dto.SelectedOptionId);
            if (selectedOption == null)
                return ApiResponse<LessonAnswerResultDto>.FailureResponse(InvalidOptionMessage, new List<string> { InvalidOptionMessage });

            var existingAnswer = await _unitOfWork.LessonQuestionAnswers.GetFirstOrDefaultAsync(
                a => a.ParentId == parentId && a.LessonQuestionId == questionId);
            if (existingAnswer != null)
                return ApiResponse<LessonAnswerResultDto>.FailureResponse(AlreadyAnsweredMessage, new List<string> { AlreadyAnsweredMessage });

            var parent = await _unitOfWork.Parents.GetByIdAsync(parentId);
            if (parent == null)
                return ApiResponse<LessonAnswerResultDto>.FailureResponse("غير مصرح", new List<string> { "غير مصرح" });

            var isCorrect = selectedOption.IsCorrect;
            var starsEarned = isCorrect ? question.StarsReward : 0;
            var correctOptionId = question.Options.First(o => o.IsCorrect).Id;

            bool isQuizCompleted = false;
            int totalLessonStarsEarned = progress.TotalStarsEarned;

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                await _unitOfWork.LessonQuestionAnswers.AddAsync(new LessonQuestionAnswer
                {
                    Id = Guid.NewGuid(),
                    ParentId = parentId,
                    LessonQuestionId = questionId,
                    SelectedOptionId = dto.SelectedOptionId,
                    IsCorrect = isCorrect,
                    StarsEarned = starsEarned,
                    AnsweredAt = DateTime.UtcNow
                });

                if (isCorrect)
                {
                    parent.StarsBalance += starsEarned;
                    await _unitOfWork.Parents.UpdateAsync(parent);
                }

                progress.TotalStarsEarned += starsEarned;
                totalLessonStarsEarned = progress.TotalStarsEarned;

                // Check if all questions are now answered
                var answeredCount = await CountAnsweredQuestionsAsync(parentId, lessonId);
                var totalQuestionsCount = await CountLessonQuestionsAsync(lessonId);

                if (answeredCount + 1 >= totalQuestionsCount)
                {
                    progress.IsQuizCompleted = true;
                    progress.QuizCompletedAt = DateTime.UtcNow;
                    isQuizCompleted = true;
                }

                await _unitOfWork.LessonProgresses.UpdateAsync(progress);
            });

            var message = isCorrect
                ? $"إجابة صحيحة! حصلت على {starsEarned} نجوم"
                : "إجابة خاطئة، حاول مع السؤال التالي!";

            return ApiResponse<LessonAnswerResultDto>.SuccessResponse(new LessonAnswerResultDto
            {
                IsCorrect = isCorrect,
                StarsEarned = starsEarned,
                CorrectOptionId = correctOptionId,
                NewStarsBalance = parent.StarsBalance,
                IsQuizCompleted = isQuizCompleted,
                TotalLessonStarsEarned = totalLessonStarsEarned
            }, message);
        }
        catch (DbUpdateException ex) when (IsUniqueViolation(ex))
        {
            return ApiResponse<LessonAnswerResultDto>.FailureResponse(AlreadyAnsweredMessage, new List<string> { AlreadyAnsweredMessage });
        }
        catch
        {
            return ApiResponse<LessonAnswerResultDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    // ─── Private helpers ──────────────────────────────────────────────────────

    private async Task<int> CountAnsweredQuestionsAsync(Guid parentId, Guid lessonId)
    {
        var answers = await _unitOfWork.LessonQuestionAnswers.FindAsync(
            a => a.ParentId == parentId && a.LessonQuestion.LessonId == lessonId);
        return answers.Count();
    }

    private async Task<int> CountLessonQuestionsAsync(Guid lessonId)
    {
        var questions = await _unitOfWork.LessonQuestions.FindAsync(q => q.LessonId == lessonId);
        return questions.Count();
    }

    private async Task<LessonEntity?> GetLessonWithFullDetailsAsync(Guid lessonId)
    {
        return await _unitOfWork.Lessons.GetFirstOrDefaultAsync(
            l => l.Id == lessonId,
            "Category,Questions,Questions.Options,Questions.Answers,Progresses");
    }

    private static List<LessonQuestionEntity> BuildQuestions(List<CreateLessonQuestionDto> dtos)
    {
        return dtos.Select((q, qi) => new LessonQuestionEntity
        {
            Id = Guid.NewGuid(),
            QuestionText = q.QuestionText.Trim(),
            StarsReward = q.StarsReward,
            OrderIndex = qi,
            Options = q.Options.Select((o, oi) => new LessonQuestionOptionEntity
            {
                Id = Guid.NewGuid(),
                OptionText = o.OptionText.Trim(),
                IsCorrect = o.IsCorrect,
                OrderIndex = oi
            }).ToList()
        }).ToList();
    }

    private static LessonAdminDetailDto MapAdminDetailDto(LessonEntity lesson, string categoryNameAr)
    {
        return new LessonAdminDetailDto
        {
            Id = lesson.Id,
            CategoryId = lesson.CategoryId,
            CategoryNameAr = categoryNameAr,
            TitleAr = lesson.TitleAr,
            ContentAr = lesson.ContentAr,
            ImageUrl = lesson.ImageUrl,
            VideoUrl = lesson.VideoUrl,
            IsActive = lesson.IsActive,
            TotalStarsReward = lesson.Questions.Sum(q => q.StarsReward),
            TotalReads = lesson.Progresses.Count(p => p.IsRead),
            TotalCompletions = lesson.Progresses.Count(p => p.IsQuizCompleted),
            Questions = lesson.Questions.OrderBy(q => q.OrderIndex).Select(q => new LessonAdminQuestionDto
            {
                Id = q.Id,
                QuestionText = q.QuestionText,
                StarsReward = q.StarsReward,
                OrderIndex = q.OrderIndex,
                Options = q.Options.OrderBy(o => o.OrderIndex).Select(o => new LessonAdminOptionDto
                {
                    Id = o.Id,
                    OptionText = o.OptionText,
                    IsCorrect = o.IsCorrect,
                    OrderIndex = o.OrderIndex
                }).ToList()
            }).ToList(),
            CreatedAt = lesson.CreatedAt,
            UpdatedAt = lesson.UpdatedAt
        };
    }

    private static LessonCategoryDto MapCategoryDto(LessonCategory category, int lessonCount)
    {
        return new LessonCategoryDto
        {
            Id = category.Id,
            NameAr = category.NameAr,
            NameEn = category.NameEn,
            OrderIndex = category.OrderIndex,
            IsActive = category.IsActive,
            LessonCount = lessonCount
        };
    }

    private static List<string> ValidateCategory(string nameAr)
    {
        var errors = new List<string>();
        if (string.IsNullOrWhiteSpace(nameAr) || nameAr.Trim().Length > 100)
            errors.Add("اسم التصنيف مطلوب ولا يتجاوز 100 حرف");
        return errors;
    }

    private static List<string> ValidateLesson(string titleAr, string contentAr, List<CreateLessonQuestionDto>? questions)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(titleAr) || titleAr.Trim().Length > 200)
            errors.Add("عنوان الدرس مطلوب ولا يتجاوز 200 حرف");

        if (string.IsNullOrWhiteSpace(contentAr) || contentAr.Trim().Length > 10000)
            errors.Add("محتوى الدرس مطلوب ولا يتجاوز 10000 حرف");

        if (questions == null || questions.Count == 0)
        {
            errors.Add("يجب إضافة سؤال واحد على الأقل");
            return errors;
        }

        foreach (var (q, i) in questions.Select((q, i) => (q, i)))
        {
            if (string.IsNullOrWhiteSpace(q.QuestionText) || q.QuestionText.Trim().Length > 500)
                errors.Add($"السؤال {i + 1}: نص السؤال مطلوب ولا يتجاوز 500 حرف");

            if (q.StarsReward <= 0)
                errors.Add($"السؤال {i + 1}: عدد النجوم يجب أن يكون أكبر من صفر");

            if (q.Options == null || q.Options.Count < 2)
                errors.Add($"السؤال {i + 1}: يجب إضافة خيارين على الأقل");
            else
            {
                if (q.Options.Any(o => string.IsNullOrWhiteSpace(o.OptionText) || o.OptionText.Trim().Length > 300))
                    errors.Add($"السؤال {i + 1}: نص كل خيار مطلوب ولا يتجاوز 300 حرف");

                if (q.Options.Count(o => o.IsCorrect) != 1)
                    errors.Add($"السؤال {i + 1}: يجب تحديد إجابة صحيحة واحدة فقط");
            }
        }

        return errors;
    }

    private static bool IsUniqueViolation(DbUpdateException exception)
    {
        var message = exception.InnerException?.Message ?? exception.Message;
        return message.Contains("UNIQUE", StringComparison.OrdinalIgnoreCase)
            || message.Contains("duplicate", StringComparison.OrdinalIgnoreCase);
    }
}
