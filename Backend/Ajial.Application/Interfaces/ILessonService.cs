using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Lesson;

namespace Ajial.Application.Interfaces;

public interface ILessonService
{
    // Admin — Categories
    Task<ApiResponse<LessonCategoryDto>> CreateCategoryAsync(CreateLessonCategoryDto dto);
    Task<ApiResponse<List<LessonCategoryDto>>> GetCategoriesAsync(bool? isActive);
    Task<ApiResponse<LessonCategoryDto>> UpdateCategoryAsync(Guid categoryId, UpdateLessonCategoryDto dto);
    Task<ApiResponse<bool>> DeleteCategoryAsync(Guid categoryId);

    // Admin — Lessons
    Task<ApiResponse<LessonAdminDetailDto>> CreateLessonAsync(CreateLessonDto dto, Guid adminUserId);
    Task<ApiResponse<List<LessonAdminListDto>>> GetAllLessonsAdminAsync(Guid? categoryId, bool? isActive);
    Task<ApiResponse<LessonAdminDetailDto>> GetLessonByIdAdminAsync(Guid lessonId);
    Task<ApiResponse<LessonAdminDetailDto>> UpdateLessonAsync(Guid lessonId, UpdateLessonDto dto);
    Task<ApiResponse<bool>> DeleteLessonAsync(Guid lessonId);
    Task<ApiResponse<LessonAdminDetailDto>> ActivateLessonAsync(Guid lessonId);
    Task<ApiResponse<LessonAdminDetailDto>> DeactivateLessonAsync(Guid lessonId);

    // Parent
    Task<ApiResponse<List<LessonCategoryDto>>> GetActiveCategoriesAsync();
    Task<ApiResponse<List<LessonCardDto>>> GetLessonsForParentAsync(GetLessonsQueryDto query, Guid parentId);
    Task<ApiResponse<LessonDetailDto>> GetLessonDetailForParentAsync(Guid lessonId, Guid parentId);
    Task<ApiResponse<MarkLessonReadResponseDto>> MarkLessonReadAsync(Guid lessonId, Guid parentId);
    Task<ApiResponse<LessonAnswerResultDto>> SubmitAnswerAsync(Guid lessonId, Guid questionId, SubmitLessonAnswerDto dto, Guid parentId);
}
