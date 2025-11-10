using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Parent;

namespace Ajial.Application.Interfaces;

public interface IParentService
{
    Task<ApiResponse<List<ParentAnalyticsDto>>> GetAllParentsForAnalyticsAsync();
}