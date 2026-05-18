using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Ranking;

namespace Ajial.Application.Interfaces;

public interface IRankingService
{
    Task<ApiResponse<PagedAdminCurrentRankingDto>> GetCurrentRankingAsync(int page, int pageSize);
    Task<ApiResponse<PublishedRankingDto>> PublishRankingAsync(PublishRankingRequestDto request);
    Task<ApiResponse<List<AdminPublishedRankingDto>>> GetRankingHistoryAsync();
    Task<ApiResponse<PagedRankingDto>> GetPublishedRankingAsync(int page, int pageSize);
    Task<ApiResponse<List<ParentBadgeDto>>> GetMyBadgesAsync(Guid userId);
}
