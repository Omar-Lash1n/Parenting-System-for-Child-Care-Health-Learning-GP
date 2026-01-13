using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajial.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Ajial.Infrastructure.Repository;

/// <summary>
/// Repository for VoiceNote entity operations
/// </summary>
public class VoiceNoteRepository : Repository<VoiceNote>, IVoiceNoteRepository
{
    public VoiceNoteRepository(ApplicationDbContext context) : base(context)
    {
    }

    /// <summary>
    /// Get all voice notes for a specific child
    /// </summary>
    public async Task<List<VoiceNote>> GetByChildIdAsync(Guid childId)
    {
        return await _dbSet
            .Where(v => v.ChildId == childId && v.IsActive)
            .OrderByDescending(v => v.CreatedAt)
            .ToListAsync();
    }

    /// <summary>
    /// Get active voice notes count for a child
    /// </summary>
    public async Task<int> GetCountByChildIdAsync(Guid childId)
    {
        return await _dbSet
            .CountAsync(v => v.ChildId == childId && v.IsActive);
    }
}
