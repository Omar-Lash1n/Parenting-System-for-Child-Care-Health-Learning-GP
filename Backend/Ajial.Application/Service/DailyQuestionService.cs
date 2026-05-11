using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.DailyQuestion;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;
using Microsoft.EntityFrameworkCore;
using DailyQuestionEntity = Ajial.Domain.Entities.DailyQuestion;
using DailyQuestionOptionEntity = Ajial.Domain.Entities.DailyQuestionOption;

namespace Ajial.Application.Service;

public class DailyQuestionService : IDailyQuestionService
{
    private const string InvalidDataMessage = "بيانات غير صحيحة";
    private const string QuestionNotFoundMessage = "السؤال غير موجود";
    private const string QuestionNotActiveMessage = "هذا السؤال غير نشط حالياً";
    private const string InvalidOptionMessage = "الخيار غير صالح لهذا السؤال";
    private const string AlreadyAnsweredMessage = "لقد أجبت على هذا السؤال مسبقاً";
    private const string EditAnsweredQuestionMessage = "لا يمكن تعديل سؤال تمت الإجابة عليه";
    private const string DeleteAnsweredQuestionMessage = "لا يمكن حذف سؤال تمت الإجابة عليه";
    private const string ServerErrorMessage = "حدث خطأ في الخادم";

    private readonly IUnitOfWork _unitOfWork;

    public DailyQuestionService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<ApiResponse<DailyQuestionAdminDto>> CreateQuestionAsync(CreateDailyQuestionDto dto, Guid adminUserId)
    {
        var validationErrors = ValidateQuestion(dto.QuestionText, dto.StarsReward, dto.Options);
        if (validationErrors.Count > 0)
            return ApiResponse<DailyQuestionAdminDto>.FailureResponse(InvalidDataMessage, validationErrors);

        try
        {
            var question = new DailyQuestionEntity
            {
                Id = Guid.NewGuid(),
                QuestionText = dto.QuestionText.Trim(),
                StarsReward = dto.StarsReward,
                IsActive = dto.IsActive,
                CreatedByAdminId = adminUserId,
                CreatedAt = DateTime.UtcNow,
                Options = dto.Options.Select((option, index) => new DailyQuestionOptionEntity
                {
                    Id = Guid.NewGuid(),
                    OptionText = option.OptionText.Trim(),
                    IsCorrect = option.IsCorrect,
                    OrderIndex = index
                }).ToList()
            };

            if (dto.IsActive)
            {
                await _unitOfWork.ExecuteInTransactionAsync(async () =>
                {
                    await DeactivateActiveQuestionsAsync();
                    await _unitOfWork.SaveChangesAsync();
                    await _unitOfWork.DailyQuestions.AddAsync(question);
                });
            }
            else
            {
                await _unitOfWork.DailyQuestions.AddAsync(question);
                await _unitOfWork.SaveChangesAsync();
            }

            return ApiResponse<DailyQuestionAdminDto>.SuccessResponse(await BuildAdminDtoAsync(question.Id), "تم إنشاء السؤال بنجاح");
        }
        catch
        {
            return ApiResponse<DailyQuestionAdminDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<List<DailyQuestionAdminListDto>>> GetAllQuestionsAsync(bool? isActive)
    {
        try
        {
            var questions = await _unitOfWork.DailyQuestions.GetAllAsync(query =>
                query.Include(q => q.Answers).OrderByDescending(q => q.CreatedAt));

            if (isActive.HasValue)
                questions = questions.Where(q => q.IsActive == isActive.Value).ToList();

            var result = questions.Select(q => new DailyQuestionAdminListDto
            {
                Id = q.Id,
                QuestionText = q.QuestionText,
                StarsReward = q.StarsReward,
                IsActive = q.IsActive,
                TotalAnswers = q.Answers.Count,
                CorrectAnswers = q.Answers.Count(a => a.IsCorrect),
                CreatedAt = q.CreatedAt
            }).ToList();

            return ApiResponse<List<DailyQuestionAdminListDto>>.SuccessResponse(result);
        }
        catch
        {
            return ApiResponse<List<DailyQuestionAdminListDto>>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<DailyQuestionAdminDto>> GetQuestionByIdAsync(Guid questionId)
    {
        try
        {
            var question = await GetQuestionWithDetailsAsync(questionId);
            if (question == null)
                return ApiResponse<DailyQuestionAdminDto>.FailureResponse(QuestionNotFoundMessage, new List<string> { QuestionNotFoundMessage });

            return ApiResponse<DailyQuestionAdminDto>.SuccessResponse(MapAdminDto(question));
        }
        catch
        {
            return ApiResponse<DailyQuestionAdminDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<DailyQuestionAdminDto>> UpdateQuestionAsync(Guid questionId, UpdateDailyQuestionDto dto)
    {
        var validationErrors = ValidateQuestion(dto.QuestionText, dto.StarsReward, dto.Options);
        if (validationErrors.Count > 0)
            return ApiResponse<DailyQuestionAdminDto>.FailureResponse(InvalidDataMessage, validationErrors);

        try
        {
            var question = await GetQuestionWithDetailsAsync(questionId);
            if (question == null)
                return ApiResponse<DailyQuestionAdminDto>.FailureResponse(QuestionNotFoundMessage, new List<string> { QuestionNotFoundMessage });

            if (question.Answers.Any())
                return ApiResponse<DailyQuestionAdminDto>.FailureResponse(EditAnsweredQuestionMessage, new List<string> { EditAnsweredQuestionMessage });

            foreach (var option in question.Options.ToList())
                await _unitOfWork.DailyQuestionOptions.DeleteAsync(option);

            question.QuestionText = dto.QuestionText.Trim();
            question.StarsReward = dto.StarsReward;
            question.UpdatedAt = DateTime.UtcNow;
            question.Options = dto.Options.Select((option, index) => new DailyQuestionOptionEntity
            {
                Id = Guid.NewGuid(),
                DailyQuestionId = question.Id,
                OptionText = option.OptionText.Trim(),
                IsCorrect = option.IsCorrect,
                OrderIndex = index
            }).ToList();

            await _unitOfWork.DailyQuestions.UpdateAsync(question);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<DailyQuestionAdminDto>.SuccessResponse(await BuildAdminDtoAsync(question.Id), "تم تحديث السؤال بنجاح");
        }
        catch
        {
            return ApiResponse<DailyQuestionAdminDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<DailyQuestionAdminDto>> ActivateQuestionAsync(Guid questionId)
    {
        try
        {
            var question = await _unitOfWork.DailyQuestions.GetByIdAsync(questionId);
            if (question == null)
                return ApiResponse<DailyQuestionAdminDto>.FailureResponse(QuestionNotFoundMessage, new List<string> { QuestionNotFoundMessage });

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                await DeactivateActiveQuestionsAsync();
                await _unitOfWork.SaveChangesAsync();
                question.IsActive = true;
                question.UpdatedAt = DateTime.UtcNow;
                await _unitOfWork.DailyQuestions.UpdateAsync(question);
            });

            return ApiResponse<DailyQuestionAdminDto>.SuccessResponse(await BuildAdminDtoAsync(question.Id), "تم تفعيل السؤال بنجاح");
        }
        catch
        {
            return ApiResponse<DailyQuestionAdminDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<DailyQuestionAdminDto>> DeactivateQuestionAsync(Guid questionId)
    {
        try
        {
            var question = await _unitOfWork.DailyQuestions.GetByIdAsync(questionId);
            if (question == null)
                return ApiResponse<DailyQuestionAdminDto>.FailureResponse(QuestionNotFoundMessage, new List<string> { QuestionNotFoundMessage });

            question.IsActive = false;
            question.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.DailyQuestions.UpdateAsync(question);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<DailyQuestionAdminDto>.SuccessResponse(await BuildAdminDtoAsync(question.Id), "تم إلغاء تفعيل السؤال بنجاح");
        }
        catch
        {
            return ApiResponse<DailyQuestionAdminDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<bool>> ResetAllQuestionsAsync()
    {
        try
        {
            var activeQuestions = await _unitOfWork.DailyQuestions.FindAsync(q => q.IsActive);
            foreach (var question in activeQuestions)
            {
                question.IsActive = false;
                question.UpdatedAt = DateTime.UtcNow;
                await _unitOfWork.DailyQuestions.UpdateAsync(question);
            }

            await _unitOfWork.SaveChangesAsync();
            return ApiResponse<bool>.SuccessResponse(true, "تم إلغاء تفعيل جميع الأسئلة");
        }
        catch
        {
            return ApiResponse<bool>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<bool>> DeleteQuestionAsync(Guid questionId)
    {
        try
        {
            var question = await GetQuestionWithDetailsAsync(questionId);
            if (question == null)
                return ApiResponse<bool>.FailureResponse(QuestionNotFoundMessage, new List<string> { QuestionNotFoundMessage });

            if (question.Answers.Any())
                return ApiResponse<bool>.FailureResponse(DeleteAnsweredQuestionMessage, new List<string> { DeleteAnsweredQuestionMessage });

            await _unitOfWork.DailyQuestions.DeleteAsync(question);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<bool>.SuccessResponse(true, "تم حذف السؤال بنجاح");
        }
        catch
        {
            return ApiResponse<bool>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<ActiveDailyQuestionDto>> GetActiveQuestionForParentAsync(Guid parentId)
    {
        try
        {
            var question = await _unitOfWork.DailyQuestions.GetFirstOrDefaultAsync(q => q.IsActive, "Options");
            if (question == null)
                return ApiResponse<ActiveDailyQuestionDto>.SuccessResponse(null!, "لا يوجد سؤال نشط حالياً");

            var answer = await _unitOfWork.DailyQuestionAnswers.GetFirstOrDefaultAsync(a =>
                a.ParentId == parentId && a.DailyQuestionId == question.Id);

            var correctOptionId = question.Options.First(o => o.IsCorrect).Id;

            return ApiResponse<ActiveDailyQuestionDto>.SuccessResponse(new ActiveDailyQuestionDto
            {
                Id = question.Id,
                QuestionText = question.QuestionText,
                StarsReward = question.StarsReward,
                Options = question.Options
                    .OrderBy(o => o.OrderIndex)
                    .Select(o => new ParentQuestionOptionDto
                    {
                        Id = o.Id,
                        OptionText = o.OptionText,
                        OrderIndex = o.OrderIndex
                    })
                    .ToList(),
                HasAnswered = answer != null,
                PreviousAnswer = answer == null ? null : new PreviousAnswerDto
                {
                    SelectedOptionId = answer.SelectedOptionId,
                    IsCorrect = answer.IsCorrect,
                    StarsEarned = answer.StarsEarned,
                    CorrectOptionId = correctOptionId
                }
            });
        }
        catch
        {
            return ApiResponse<ActiveDailyQuestionDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    public async Task<ApiResponse<DailyQuestionAnswerResultDto>> SubmitAnswerAsync(Guid questionId, SubmitDailyQuestionAnswerDto dto, Guid parentId)
    {
        if (dto.SelectedOptionId == Guid.Empty)
            return ApiResponse<DailyQuestionAnswerResultDto>.FailureResponse("لم يتم اختيار إجابة", new List<string> { "لم يتم اختيار إجابة" });

        try
        {
            var question = await _unitOfWork.DailyQuestions.GetFirstOrDefaultAsync(q => q.Id == questionId, "Options");
            if (question == null)
                return ApiResponse<DailyQuestionAnswerResultDto>.FailureResponse(QuestionNotFoundMessage, new List<string> { QuestionNotFoundMessage });

            if (!question.IsActive)
                return ApiResponse<DailyQuestionAnswerResultDto>.FailureResponse(QuestionNotActiveMessage, new List<string> { QuestionNotActiveMessage });

            var selectedOption = question.Options.FirstOrDefault(o => o.Id == dto.SelectedOptionId);
            if (selectedOption == null)
                return ApiResponse<DailyQuestionAnswerResultDto>.FailureResponse(InvalidOptionMessage, new List<string> { InvalidOptionMessage });

            var existingAnswer = await _unitOfWork.DailyQuestionAnswers.GetFirstOrDefaultAsync(a =>
                a.ParentId == parentId && a.DailyQuestionId == questionId);
            if (existingAnswer != null)
                return ApiResponse<DailyQuestionAnswerResultDto>.FailureResponse(AlreadyAnsweredMessage, new List<string> { AlreadyAnsweredMessage });

            var parent = await _unitOfWork.Parents.GetByIdAsync(parentId);
            if (parent == null)
                return ApiResponse<DailyQuestionAnswerResultDto>.FailureResponse("غير مصرح", new List<string> { "غير مصرح" });

            var isCorrect = selectedOption.IsCorrect;
            var starsEarned = isCorrect ? question.StarsReward : 0;
            var correctOptionId = question.Options.First(o => o.IsCorrect).Id;

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                await _unitOfWork.DailyQuestionAnswers.AddAsync(new DailyQuestionAnswer
                {
                    Id = Guid.NewGuid(),
                    DailyQuestionId = question.Id,
                    ParentId = parent.Id,
                    SelectedOptionId = selectedOption.Id,
                    IsCorrect = isCorrect,
                    StarsEarned = starsEarned,
                    AnsweredAt = DateTime.UtcNow
                });

                if (isCorrect)
                {
                    parent.StarsBalance += starsEarned;
                    await _unitOfWork.Parents.UpdateAsync(parent);
                }
            });

            var result = new DailyQuestionAnswerResultDto
            {
                IsCorrect = isCorrect,
                StarsEarned = starsEarned,
                CorrectOptionId = correctOptionId,
                NewStarsBalance = parent.StarsBalance
            };

            var message = isCorrect
                ? $"إجابة صحيحة! حصلت على {starsEarned} نجوم"
                : "إجابة خاطئة، حاول في السؤال القادم!";

            return ApiResponse<DailyQuestionAnswerResultDto>.SuccessResponse(result, message);
        }
        catch (DbUpdateException ex) when (IsUniqueViolation(ex))
        {
            return ApiResponse<DailyQuestionAnswerResultDto>.FailureResponse(AlreadyAnsweredMessage, new List<string> { AlreadyAnsweredMessage });
        }
        catch
        {
            return ApiResponse<DailyQuestionAnswerResultDto>.FailureResponse(ServerErrorMessage, new List<string> { ServerErrorMessage });
        }
    }

    private async Task DeactivateActiveQuestionsAsync()
    {
        var activeQuestions = await _unitOfWork.DailyQuestions.FindAsync(q => q.IsActive);
        foreach (var activeQuestion in activeQuestions)
        {
            activeQuestion.IsActive = false;
            activeQuestion.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.DailyQuestions.UpdateAsync(activeQuestion);
        }
    }

    private async Task<DailyQuestionAdminDto> BuildAdminDtoAsync(Guid questionId)
    {
        var question = await GetQuestionWithDetailsAsync(questionId);
        return MapAdminDto(question!);
    }

    private async Task<DailyQuestionEntity?> GetQuestionWithDetailsAsync(Guid questionId)
    {
        return await _unitOfWork.DailyQuestions.GetFirstOrDefaultAsync(q => q.Id == questionId, "Options,Answers");
    }

    private static DailyQuestionAdminDto MapAdminDto(DailyQuestionEntity question)
    {
        return new DailyQuestionAdminDto
        {
            Id = question.Id,
            QuestionText = question.QuestionText,
            StarsReward = question.StarsReward,
            IsActive = question.IsActive,
            Options = question.Options
                .OrderBy(o => o.OrderIndex)
                .Select(o => new DailyQuestionAdminOptionDto
                {
                    Id = o.Id,
                    OptionText = o.OptionText,
                    IsCorrect = o.IsCorrect,
                    OrderIndex = o.OrderIndex
                })
                .ToList(),
            TotalAnswers = question.Answers.Count,
            CorrectAnswers = question.Answers.Count(a => a.IsCorrect),
            CreatedAt = question.CreatedAt
        };
    }

    private static List<string> ValidateQuestion(string questionText, int starsReward, List<DailyQuestionOptionDto>? options)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(questionText) || questionText.Trim().Length > 500)
            errors.Add("نص السؤال مطلوب ويجب ألا يتجاوز 500 حرف");

        if (starsReward <= 0)
            errors.Add("عدد النجوم يجب أن يكون أكبر من صفر");

        if (options == null || options.Count < 2)
        {
            errors.Add("يجب إضافة خيارين على الأقل");
            return errors;
        }

        if (options.Any(o => string.IsNullOrWhiteSpace(o.OptionText) || o.OptionText.Trim().Length > 300))
            errors.Add("نص كل خيار مطلوب ويجب ألا يتجاوز 300 حرف");

        if (options.Count(o => o.IsCorrect) != 1)
            errors.Add("يجب تحديد إجابة صحيحة واحدة فقط");

        return errors;
    }

    private static bool IsUniqueViolation(DbUpdateException exception)
    {
        var message = exception.InnerException?.Message ?? exception.Message;
        return message.Contains("IX_DailyQuestionAnswers_ParentId_DailyQuestionId", StringComparison.OrdinalIgnoreCase)
            || message.Contains("UNIQUE", StringComparison.OrdinalIgnoreCase)
            || message.Contains("duplicate", StringComparison.OrdinalIgnoreCase);
    }
}
