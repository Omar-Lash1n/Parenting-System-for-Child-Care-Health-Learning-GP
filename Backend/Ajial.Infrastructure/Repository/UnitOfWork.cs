using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajial.Infrastructure.Data;
using Ajlal.Application.Interfaces;
using Microsoft.EntityFrameworkCore.Storage;

namespace Ajial.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly ApplicationDbContext _context;
    private IDbContextTransaction? _transaction;

    public IRepository<User> Users { get; }
    public IRepository<Parent> Parents { get; }
    public IRepository<City> Cities { get; }

    public UnitOfWork(ApplicationDbContext context)
    {
        _context = context;
        Users = new Repository<User>(context);
        Parents = new Repository<Parent>(context);
        Cities = new Repository<City>(context);
    }

    public async Task<int> SaveChangesAsync()
    {
        return await _context.SaveChangesAsync();
    }

    public async Task BeginTransactionAsync()
    {
        _transaction = await _context.Database.BeginTransactionAsync();
    }

    public async Task CommitTransactionAsync()
    {
        if (_transaction != null)
        {
            await _transaction.CommitAsync();
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    public async Task RollbackTransactionAsync()
    {
        if (_transaction != null)
        {
            await _transaction.RollbackAsync();
            await _transaction.DisposeAsync();
            _transaction = null;
        }
    }

    public void Dispose()
    {
        _transaction?.Dispose();
        _context.Dispose();
    }
}