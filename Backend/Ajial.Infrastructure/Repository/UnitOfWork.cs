using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajial.Infrastructure.Data;
using Ajlal.Application.Interfaces;
using Microsoft.EntityFrameworkCore;
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
    public IRepository<HealthUnit> HealthUnits { get; private set; }       // ✅ Health Unit Search Feature
    public IRepository<ChildTask> ChildTasks { get; private set; }                      // ✅ Child Tasks Feature
    public IRepository<ChildTaskAssignee> ChildTaskAssignees { get; private set; }     // ✅ Child Tasks Feature
    public IRepository<ChildTaskRecurrence> ChildTaskRecurrences { get; private set; } // ✅ Child Tasks Feature
    public IRepository<Prize> Prizes { get; private set; }
    public IRepository<PrizeTask> PrizeTasks { get; private set; }
    public IRepository<DailyQuestion> DailyQuestions { get; private set; }
    public IRepository<DailyQuestionOption> DailyQuestionOptions { get; private set; }
    public IRepository<DailyQuestionAnswer> DailyQuestionAnswers { get; private set; }
    public IRepository<SpecialistStatusHistory> SpecialistStatusHistories { get; private set; }
    public IRepository<Specialty> Specialties { get; private set; }
    public IRepository<LessonCategory> LessonCategories { get; private set; }         // ✅ Lesson Feature
    public IRepository<Lesson> Lessons { get; private set; }                          // ✅ Lesson Feature
    public IRepository<LessonQuestion> LessonQuestions { get; private set; }          // ✅ Lesson Feature
    public IRepository<LessonQuestionOption> LessonQuestionOptions { get; private set; } // ✅ Lesson Feature
    public IRepository<LessonProgress> LessonProgresses { get; private set; }         // ✅ Lesson Feature
    public IRepository<LessonQuestionAnswer> LessonQuestionAnswers { get; private set; } // ✅ Lesson Feature
    public IRepository<RankingCycle> RankingCycles { get; private set; }                // ✅ Ranking Feature
    public IRepository<RankingEntry> RankingEntries { get; private set; }               // ✅ Ranking Feature
    public IRepository<Clinic> Clinics { get; private set; }                            // ✅ Clinic Feature
    public IRepository<RemoteConsultation> RemoteConsultations { get; private set; }    // ✅ Remote Consultation Feature

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
        HealthUnits = new Repository<HealthUnit>(_context);       // ✅ Health Unit Search Feature
        ChildTasks = new Repository<ChildTask>(_context);                      // ✅ Child Tasks Feature
        ChildTaskAssignees = new Repository<ChildTaskAssignee>(_context);     // ✅ Child Tasks Feature
        ChildTaskRecurrences = new Repository<ChildTaskRecurrence>(_context); // ✅ Child Tasks Feature
        Prizes = new Repository<Prize>(_context);
        PrizeTasks = new Repository<PrizeTask>(_context);
        DailyQuestions = new Repository<DailyQuestion>(_context);
        DailyQuestionOptions = new Repository<DailyQuestionOption>(_context);
        DailyQuestionAnswers = new Repository<DailyQuestionAnswer>(_context);
        SpecialistStatusHistories = new Repository<SpecialistStatusHistory>(_context);
        Specialties = new Repository<Specialty>(_context);
        LessonCategories = new Repository<LessonCategory>(_context);         // ✅ Lesson Feature
        Lessons = new Repository<Lesson>(_context);                          // ✅ Lesson Feature
        LessonQuestions = new Repository<LessonQuestion>(_context);          // ✅ Lesson Feature
        LessonQuestionOptions = new Repository<LessonQuestionOption>(_context); // ✅ Lesson Feature
        LessonProgresses = new Repository<LessonProgress>(_context);         // ✅ Lesson Feature
        LessonQuestionAnswers = new Repository<LessonQuestionAnswer>(_context); // ✅ Lesson Feature
        RankingCycles = new Repository<RankingCycle>(_context);                // ✅ Ranking Feature
        RankingEntries = new Repository<RankingEntry>(_context);               // ✅ Ranking Feature
        Clinics = new Repository<Clinic>(_context);                            // ✅ Clinic Feature
        RemoteConsultations = new Repository<RemoteConsultation>(_context);    // ✅ Remote Consultation Feature
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

    public async Task ExecuteInTransactionAsync(Func<Task> operation)
    {
        var strategy = _context.Database.CreateExecutionStrategy();

        await strategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                await operation();
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        });
    }

    public void Dispose()
    {
        _transaction?.Dispose();
        _context.Dispose();
    }
}
