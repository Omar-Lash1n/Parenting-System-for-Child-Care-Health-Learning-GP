using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajial.Infrastructure.Data;
using Ajlal.Application.Interfaces;
using Microsoft.EntityFrameworkCore.Storage;

namespace Ajial.Infrastructure.Repository;

public class UnitOfWork : IUnitOfWork
{
    private readonly ApplicationDbContext _context;
    private IDbContextTransaction? _transaction;

    public IRepository<User> Users { get; private set; }
    public IRepository<Parent> Parents { get; private set; }
    public IRepository<City> Cities { get; private set; }
    public IRepository<PasswordResetToken> PasswordResetTokens { get; private set; }
    public IRepository<EmailVerificationToken> EmailVerificationTokens { get; private set; }
    public IChildRepository Children { get; private set; }
    public IVoiceNoteRepository VoiceNotes { get; private set; }
    public IRepository<VaccinationMilestone> VaccinationMilestones { get; private set; }
    public IRepository<ChildVaccination> ChildVaccinations { get; private set; }
    public IRepository<Specialist> Specialists { get; private set; }
    public IRepository<VaccinationAppointment> VaccinationAppointments { get; private set; }  // ✅ Vaccination Reminders
    public IRepository<TaskCategory> TaskCategories { get; private set; }  // ✅ Task Feature
    public IRepository<ParentTask> Tasks { get; private set; }             // ✅ Task Feature
    public IRepository<TaskAssignee> TaskAssignees { get; private set; }   // ✅ Task Feature

    public UnitOfWork(ApplicationDbContext context)
    {
        _context = context;

        Users = new Repository<User>(_context);
        Parents = new Repository<Parent>(_context);
        Cities = new Repository<City>(_context);
        PasswordResetTokens = new Repository<PasswordResetToken>(_context);
        EmailVerificationTokens = new Repository<EmailVerificationToken>(_context);
        Children = new ChildRepository(_context);
        VoiceNotes = new VoiceNoteRepository(_context);
        VaccinationMilestones = new Repository<VaccinationMilestone>(_context);
        ChildVaccinations = new Repository<ChildVaccination>(_context);
        Specialists = new Repository<Specialist>(_context);
        VaccinationAppointments = new Repository<VaccinationAppointment>(_context);  // ✅ Vaccination Reminders
        TaskCategories = new Repository<TaskCategory>(_context);  // ✅ Task Feature
        Tasks = new Repository<ParentTask>(_context);             // ✅ Task Feature
        TaskAssignees = new Repository<TaskAssignee>(_context);   // ✅ Task Feature
    }

    public async Task<int> SaveChangesAsync()
    {
        return await _context.SaveChangesAsync();
    }

    public async Task<int> SaveAsync()
    {
        return await _context.SaveChangesAsync();
    }

    public async Task BeginTransactionAsync()
    {
        _transaction = await _context.Database.BeginTransactionAsync();
    }

    public async Task CommitTransactionAsync()
    {
        try
        {
            await _context.SaveChangesAsync();
            if (_transaction != null)
            {
                await _transaction.CommitAsync();
            }
        }
        catch
        {
            await RollbackTransactionAsync();
            throw;
        }
        finally
        {
            if (_transaction != null)
            {
                await _transaction.DisposeAsync();
                _transaction = null;
            }
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