using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajial.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace Ajial.Infrastructure.Repository;

public class ChildRepository : Repository<Child>, IChildRepository
{
    public ChildRepository(ApplicationDbContext context) : base(context)
    {
    }

    public async Task<Child?> GetByChildLoginIdAsync(string childLoginId)
    {
        return await _dbSet
            .Include(c => c.Parent)
            .ThenInclude(p => p.User)
            .FirstOrDefaultAsync(c => c.ChildLoginId == childLoginId);
    }

    public async Task<List<Child>> GetChildrenByParentIdAsync(Guid parentId)
    {
        return await _dbSet
            .Where(c => c.ParentId == parentId && c.IsActive)
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync();
    }

    public async Task<bool> IsChildLoginIdExistsAsync(string childLoginId)
    {
        return await _dbSet.AnyAsync(c => c.ChildLoginId == childLoginId);
    }
}