using Ajial.Domain.Entities;

namespace Ajial.Application.Interfaces;

public interface IChildRepository : IRepository<Child>
{
    Task<Child?> GetByChildLoginIdAsync(string childLoginId);
    Task<List<Child>> GetChildrenByParentIdAsync(Guid parentId);
    Task<bool> IsChildLoginIdExistsAsync(string childLoginId);
}