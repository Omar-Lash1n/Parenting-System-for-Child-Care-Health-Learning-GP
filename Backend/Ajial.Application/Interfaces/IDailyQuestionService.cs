using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.DailyQuestion;

namespace Ajial.Application.Interfaces;

public interface IDailyQuestionService
{
    Task<ApiResponse<DailyQuestionAdminDto>> CreateQuestionAsync(CreateDailyQuestionDto dto, Guid adminUserId);
    Task<ApiResponse<List<DailyQuestionAdminListDto>>> GetAllQuestionsAsync(bool? isActive);
    Task<ApiResponse<DailyQuestionAdminDto>> GetQuestionByIdAsync(Guid questionId);
    Task<ApiResponse<DailyQuestionAdminDto>> UpdateQuestionAsync(Guid questionId, UpdateDailyQuestionDto dto);
    Task<ApiResponse<DailyQuestionAdminDto>> ActivateQuestionAsync(Guid questionId);
    Task<ApiResponse<DailyQuestionAdminDto>> DeactivateQuestionAsync(Guid questionId);
    Task<ApiResponse<bool>> ResetAllQuestionsAsync();
    Task<ApiResponse<bool>> DeleteQuestionAsync(Guid questionId);
    Task<ApiResponse<ActiveDailyQuestionDto>> GetActiveQuestionForParentAsync(Guid parentId);
    Task<ApiResponse<DailyQuestionAnswerResultDto>> SubmitAnswerAsync(Guid questionId, SubmitDailyQuestionAnswerDto dto, Guid parentId);
}
