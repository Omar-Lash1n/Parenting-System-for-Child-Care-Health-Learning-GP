using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Ranking;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Service;

public class RankingService : IRankingService
{
    private readonly IUnitOfWork _unitOfWork;

    public RankingService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    // ── Admin: current ranking (paginated, batch-loaded) ──────────────────────
    public async Task<ApiResponse<PagedAdminCurrentRankingDto>> GetCurrentRankingAsync(int page, int pageSize)
    {
        try
        {
            pageSize = Math.Clamp(pageSize, 1, 100);

            // 1 DB call: load all parents sorted in memory (needed for global rank numbers)
            var allParents = (await _unitOfWork.Parents.GetAllAsync())
                .OrderByDescending(p => p.StarsBalance)
                .ThenBy(p => p.CreatedAt)
                .ToList();

            int totalCount = allParents.Count;
            int totalPages = totalCount == 0 ? 1 : (int)Math.Ceiling((double)totalCount / pageSize);
            page = Math.Clamp(page, 1, totalPages);
            int skip = (page - 1) * pageSize;

            var pageParents = allParents.Skip(skip).Take(pageSize).ToList();

            if (pageParents.Count == 0)
            {
                return ApiResponse<PagedAdminCurrentRankingDto>.SuccessResponse(new PagedAdminCurrentRankingDto
                {
                    TotalParents = totalCount,
                    GeneratedAt = DateTime.Now,
                    Entries = new List<AdminCurrentRankingEntryDto>(),
                    Page = page,
                    PageSize = pageSize,
                    TotalPages = totalPages,
                    HasNextPage = false,
                    HasPreviousPage = page > 1
                }, "تم جلب الترتيب الحالي بنجاح");
            }

            // Batch-load users for this page (1 DB call instead of N)
            var userIds = pageParents.Select(p => p.UserId).ToList();
            var usersMap = (await _unitOfWork.Users.FindAsync(u => userIds.Contains(u.Id)))
                .ToDictionary(u => u.Id);

            // Batch-load children counts for this page (1 DB call instead of N)
            var parentIds = pageParents.Select(p => p.Id).ToList();
            var childrenList = await _unitOfWork.Children.FindAsync(c => parentIds.Contains(c.ParentId));
            var childrenMap = childrenList
                .GroupBy(c => c.ParentId)
                .ToDictionary(g => g.Key, g => g.Count());

            // Build DTOs (no more DB calls)
            var entries = pageParents.Select((p, i) =>
            {
                int rank = skip + i + 1;
                var user = usersMap.GetValueOrDefault(p.UserId);
                int childCount = childrenMap.GetValueOrDefault(p.Id, 0);

                string? badge = null;
                if (p.StarsBalance > 0)
                {
                    badge = rank switch
                    {
                        1 => "ذهبي",
                        2 => "فضي",
                        3 => "برونزي",
                        _ => null
                    };
                }

                return new AdminCurrentRankingEntryDto
                {
                    ParentId = p.Id,
                    FullName = user?.FullName ?? string.Empty,
                    ProfileImageUrl = p.ProfileImageUrl,
                    ChildrenCount = childCount,
                    Stars = p.StarsBalance,
                    Rank = rank,
                    ProjectedBadge = badge
                };
            }).ToList();

            return ApiResponse<PagedAdminCurrentRankingDto>.SuccessResponse(new PagedAdminCurrentRankingDto
            {
                TotalParents = totalCount,
                GeneratedAt = DateTime.Now,
                Entries = entries,
                Page = page,
                PageSize = pageSize,
                TotalPages = totalPages,
                HasNextPage = page < totalPages,
                HasPreviousPage = page > 1
            }, "تم جلب الترتيب الحالي بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<PagedAdminCurrentRankingDto>.FailureResponse(
                "حدث خطأ أثناء جلب الترتيب", new List<string> { ex.Message });
        }
    }

    // ── Admin: publish ranking ────────────────────────────────────────────────
    public async Task<ApiResponse<PublishedRankingDto>> PublishRankingAsync(PublishRankingRequestDto request)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(request.SeasonName))
                return ApiResponse<PublishedRankingDto>.FailureResponse(
                    "اسم الموسم مطلوب", new List<string> { "اسم الموسم مطلوب" });

            if (request.NextPublishAt <= DateTime.Now.AddHours(1))
                return ApiResponse<PublishedRankingDto>.FailureResponse(
                    "تاريخ النشر التالي يجب أن يكون بعد ساعة على الأقل من الآن",
                    new List<string> { "تاريخ النشر التالي يجب أن يكون بعد ساعة على الأقل من الآن" });

            PublishedRankingDto result = null!;

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                // 1 DB call: load & sort all parents
                var sorted = (await _unitOfWork.Parents.GetAllAsync())
                    .OrderByDescending(p => p.StarsBalance)
                    .ThenBy(p => p.CreatedAt)
                    .ToList();

                var cycle = new RankingCycle
                {
                    Id = Guid.NewGuid(),
                    SeasonName = request.SeasonName.Trim(),
                    PublishedAt = DateTime.Now,
                    NextPublishAt = request.NextPublishAt
                };

                await _unitOfWork.RankingCycles.AddAsync(cycle);

                // Write ranking entries
                for (int i = 0; i < sorted.Count; i++)
                {
                    var p = sorted[i];
                    int rank = i + 1;

                    BadgeType? badge = null;
                    if (p.StarsBalance > 0 && rank <= 3)
                    {
                        badge = rank switch
                        {
                            1 => BadgeType.Gold,
                            2 => BadgeType.Silver,
                            3 => BadgeType.Bronze,
                            _ => null
                        };
                    }

                    await _unitOfWork.RankingEntries.AddAsync(new RankingEntry
                    {
                        Id = Guid.NewGuid(),
                        RankingCycleId = cycle.Id,
                        ParentId = p.Id,
                        Stars = p.StarsBalance,
                        Rank = rank,
                        Badge = badge
                    });

                    p.StarsBalance = 0;
                    await _unitOfWork.Parents.UpdateAsync(p);
                }

                // Batch-load users & children for the response DTO (2 DB calls instead of N×2)
                var parentIds = sorted.Select(p => p.Id).ToList();
                var userIds = sorted.Select(p => p.UserId).ToList();

                var usersMap = (await _unitOfWork.Users.FindAsync(u => userIds.Contains(u.Id)))
                    .ToDictionary(u => u.Id);

                var childrenList = await _unitOfWork.Children.FindAsync(c => parentIds.Contains(c.ParentId));
                var childrenMap = childrenList
                    .GroupBy(c => c.ParentId)
                    .ToDictionary(g => g.Key, g => g.Count());

                var entryDtos = sorted.Select((p, i) =>
                {
                    int rank = i + 1;
                    BadgeType? badge = null;
                    if (p.StarsBalance == 0 && rank <= 3) // stars were reset; check original rank
                        badge = rank switch { 1 => BadgeType.Gold, 2 => BadgeType.Silver, 3 => BadgeType.Bronze, _ => null };

                    var user = usersMap.GetValueOrDefault(p.UserId);
                    int childCount = childrenMap.GetValueOrDefault(p.Id, 0);

                    return new RankingEntryDto
                    {
                        ParentId = p.Id,
                        FullName = user?.FullName ?? string.Empty,
                        ProfileImageUrl = p.ProfileImageUrl,
                        ChildrenCount = childCount,
                        Stars = p.StarsBalance,
                        Rank = rank,
                        Badge = badge?.ToString()
                    };
                }).ToList();

                result = new PublishedRankingDto
                {
                    CycleId = cycle.Id,
                    SeasonName = cycle.SeasonName,
                    PublishedAt = cycle.PublishedAt,
                    NextPublishAt = cycle.NextPublishAt,
                    Entries = entryDtos
                };
            });

            return ApiResponse<PublishedRankingDto>.SuccessResponse(result, "تم نشر الترتيب وإعادة تصفير النجوم بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<PublishedRankingDto>.FailureResponse(
                "حدث خطأ أثناء نشر الترتيب", new List<string> { ex.Message });
        }
    }

    // ── Admin: ranking history ────────────────────────────────────────────────
    public async Task<ApiResponse<List<AdminPublishedRankingDto>>> GetRankingHistoryAsync()
    {
        try
        {
            var cycles = (await _unitOfWork.RankingCycles.GetAllAsync())
                .OrderByDescending(c => c.PublishedAt)
                .ToList();

            var result = new List<AdminPublishedRankingDto>();

            foreach (var cycle in cycles)
            {
                // Only top 3 entries needed for history view
                var topEntries = (await _unitOfWork.RankingEntries.FindAsync(
                        e => e.RankingCycleId == cycle.Id && e.Rank <= 3))
                    .OrderBy(e => e.Rank)
                    .ToList();

                // Batch-load parents & users for top 3 only (small, fixed cost)
                var parentIds = topEntries.Select(e => e.ParentId).ToList();
                var parentsMap = (await _unitOfWork.Parents.FindAsync(p => parentIds.Contains(p.Id)))
                    .ToDictionary(p => p.Id);

                var userIds = parentsMap.Values.Select(p => p.UserId).ToList();
                var usersMap = (await _unitOfWork.Users.FindAsync(u => userIds.Contains(u.Id)))
                    .ToDictionary(u => u.Id);

                var childrenList = await _unitOfWork.Children.FindAsync(c => parentIds.Contains(c.ParentId));
                var childrenMap = childrenList
                    .GroupBy(c => c.ParentId)
                    .ToDictionary(g => g.Key, g => g.Count());

                var totalForCycle = (await _unitOfWork.RankingEntries.FindAsync(
                    e => e.RankingCycleId == cycle.Id)).Count();

                var topThree = topEntries.Select(entry =>
                {
                    var parent = parentsMap.GetValueOrDefault(entry.ParentId);
                    var user = parent != null ? usersMap.GetValueOrDefault(parent.UserId) : null;
                    int childCount = childrenMap.GetValueOrDefault(entry.ParentId, 0);

                    return new RankingEntryDto
                    {
                        ParentId = entry.ParentId,
                        FullName = user?.FullName ?? string.Empty,
                        ProfileImageUrl = parent?.ProfileImageUrl,
                        ChildrenCount = childCount,
                        Stars = entry.Stars,
                        Rank = entry.Rank,
                        Badge = entry.Badge?.ToString()
                    };
                }).ToList();

                result.Add(new AdminPublishedRankingDto
                {
                    CycleId = cycle.Id,
                    SeasonName = cycle.SeasonName,
                    PublishedAt = cycle.PublishedAt,
                    NextPublishAt = cycle.NextPublishAt,
                    TotalParents = totalForCycle,
                    TopThree = topThree
                });
            }

            return ApiResponse<List<AdminPublishedRankingDto>>.SuccessResponse(result, "تم جلب سجل الترتيب بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<List<AdminPublishedRankingDto>>.FailureResponse(
                "حدث خطأ أثناء جلب سجل الترتيب", new List<string> { ex.Message });
        }
    }

    // ── Public: published ranking (paginated, batch-loaded) ───────────────────
    public async Task<ApiResponse<PagedRankingDto>> GetPublishedRankingAsync(int page, int pageSize)
    {
        try
        {
            pageSize = Math.Clamp(pageSize, 1, 100);

            // 1 DB call: get latest cycle
            var cycle = (await _unitOfWork.RankingCycles.GetAllAsync())
                .OrderByDescending(c => c.PublishedAt)
                .FirstOrDefault();

            if (cycle == null)
                return ApiResponse<PagedRankingDto>.FailureResponse(
                    "لا يوجد ترتيب منشور بعد", new List<string> { "لا يوجد ترتيب منشور بعد" });

            // 1 DB call: get all entries for this cycle (small objects: just IDs + rank + stars)
            var allEntries = (await _unitOfWork.RankingEntries.FindAsync(e => e.RankingCycleId == cycle.Id))
                .OrderBy(e => e.Rank)
                .ToList();

            int totalCount = allEntries.Count;
            int totalPages = totalCount == 0 ? 1 : (int)Math.Ceiling((double)totalCount / pageSize);
            page = Math.Clamp(page, 1, totalPages);
            int skip = (page - 1) * pageSize;

            var pageEntries = allEntries.Skip(skip).Take(pageSize).ToList();

            if (pageEntries.Count == 0)
            {
                return ApiResponse<PagedRankingDto>.SuccessResponse(new PagedRankingDto
                {
                    CycleId = cycle.Id,
                    SeasonName = cycle.SeasonName,
                    PublishedAt = cycle.PublishedAt,
                    NextPublishAt = cycle.NextPublishAt,
                    Entries = new List<RankingEntryDto>(),
                    TotalEntries = totalCount,
                    Page = page,
                    PageSize = pageSize,
                    TotalPages = totalPages,
                    HasNextPage = false,
                    HasPreviousPage = page > 1
                }, "تم جلب الترتيب بنجاح");
            }

            // Batch-load parents for this page (1 DB call instead of pageSize calls)
            var parentIds = pageEntries.Select(e => e.ParentId).ToList();
            var parentsMap = (await _unitOfWork.Parents.FindAsync(p => parentIds.Contains(p.Id)))
                .ToDictionary(p => p.Id);

            // Batch-load users for this page (1 DB call instead of pageSize calls)
            var userIds = parentsMap.Values.Select(p => p.UserId).ToList();
            var usersMap = (await _unitOfWork.Users.FindAsync(u => userIds.Contains(u.Id)))
                .ToDictionary(u => u.Id);

            // Batch-load children counts for this page (1 DB call instead of pageSize calls)
            var childrenList = await _unitOfWork.Children.FindAsync(c => parentIds.Contains(c.ParentId));
            var childrenMap = childrenList
                .GroupBy(c => c.ParentId)
                .ToDictionary(g => g.Key, g => g.Count());

            // Build DTOs (zero additional DB calls)
            var entryDtos = pageEntries.Select(entry =>
            {
                var parent = parentsMap.GetValueOrDefault(entry.ParentId);
                var user = parent != null ? usersMap.GetValueOrDefault(parent.UserId) : null;
                int childCount = childrenMap.GetValueOrDefault(entry.ParentId, 0);

                return new RankingEntryDto
                {
                    ParentId = entry.ParentId,
                    FullName = user?.FullName ?? string.Empty,
                    ProfileImageUrl = parent?.ProfileImageUrl,
                    ChildrenCount = childCount,
                    Stars = entry.Stars,
                    Rank = entry.Rank,
                    Badge = entry.Badge?.ToString()
                };
            }).ToList();

            return ApiResponse<PagedRankingDto>.SuccessResponse(new PagedRankingDto
            {
                CycleId = cycle.Id,
                SeasonName = cycle.SeasonName,
                PublishedAt = cycle.PublishedAt,
                NextPublishAt = cycle.NextPublishAt,
                Entries = entryDtos,
                TotalEntries = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = totalPages,
                HasNextPage = page < totalPages,
                HasPreviousPage = page > 1
            }, "تم جلب الترتيب بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<PagedRankingDto>.FailureResponse(
                "حدث خطأ أثناء جلب الترتيب", new List<string> { ex.Message });
        }
    }

    // ── Parent: my badges ─────────────────────────────────────────────────────
    public async Task<ApiResponse<List<ParentBadgeDto>>> GetMyBadgesAsync(Guid userId)
    {
        try
        {
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == userId);
            if (parent == null)
                return ApiResponse<List<ParentBadgeDto>>.FailureResponse(
                    "غير مصرح", new List<string> { "لا يوجد ملف أبوي لهذا المستخدم" });

            var entries = (await _unitOfWork.RankingEntries.FindAsync(
                    e => e.ParentId == parent.Id && e.Badge != null))
                .OrderByDescending(e => e.RankingCycleId)
                .ToList();

            if (entries.Count == 0)
                return ApiResponse<List<ParentBadgeDto>>.SuccessResponse(
                    new List<ParentBadgeDto>(), "لا توجد شارات بعد");

            // Batch-load cycles for all badges (1 call instead of N)
            var cycleIds = entries.Select(e => e.RankingCycleId).Distinct().ToList();
            var cyclesMap = (await _unitOfWork.RankingCycles.FindAsync(c => cycleIds.Contains(c.Id)))
                .ToDictionary(c => c.Id);

            var badges = entries
                .Where(e => cyclesMap.ContainsKey(e.RankingCycleId))
                .Select(entry =>
                {
                    var cycle = cyclesMap[entry.RankingCycleId];
                    return new ParentBadgeDto
                    {
                        CycleId = cycle.Id,
                        SeasonName = cycle.SeasonName,
                        Badge = entry.Badge!.Value.ToString(),
                        Rank = entry.Rank,
                        Stars = entry.Stars,
                        AwardedAt = cycle.PublishedAt
                    };
                }).ToList();

            return ApiResponse<List<ParentBadgeDto>>.SuccessResponse(badges, "تم جلب الشارات بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<List<ParentBadgeDto>>.FailureResponse(
                "حدث خطأ أثناء جلب الشارات", new List<string> { ex.Message });
        }
    }
}
