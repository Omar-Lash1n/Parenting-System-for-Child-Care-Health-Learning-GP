using System.Linq.Expressions;

namespace Ajial.Application.Interfaces;

public interface IRepository<T> where T : class
{
    Task<T?> GetByIdAsync(Guid id);
    Task<T?> GetByIdAsync(int id);
    Task<T?> GetFirstOrDefaultAsync(Expression<Func<T, bool>> predicate);
    Task<IEnumerable<T>> GetAllAsync();
    Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate);
    Task<T> AddAsync(T entity);
    Task UpdateAsync(T entity);
    Task DeleteAsync(T entity);
    Task<bool> ExistsAsync(Expression<Func<T, bool>> predicate);
}