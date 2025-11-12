using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;

namespace Ajlal.Application.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IRepository<User> Users { get; }
    IRepository<Parent> Parents { get; }
    IRepository<City> Cities { get; }
    IRepository<PasswordResetToken> PasswordResetTokens { get; }  // ✅ NEW

    Task<int> SaveChangesAsync();
    Task BeginTransactionAsync();
    Task CommitTransactionAsync();
    Task RollbackTransactionAsync();
}