using Ajial.Application.DTOs.Analytics;
using Ajial.Application.DTOs.Common;

namespace Ajial.Application.Interfaces;

public interface IAnalyticsService
{
    /// <summary>
    /// Get all children with parent information (Flat structure for Power BI)
    /// </summary>
    Task<ApiResponse<List<ChildAnalyticsDto>>> GetAllChildrenAnalyticsAsync();
    
    /// <summary>
    /// Get all parents with their children (Flat structure - one row per parent-child)
    /// </summary>
    Task<ApiResponse<List<ParentChildrenFlatDto>>> GetParentsWithChildrenFlatAsync();
}