using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;

namespace Ajlal.Application.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IRepository<User> Users { get; }
    IRepository<Parent> Parents { get; }
    IRepository<City> Cities { get; }
    IRepository<PasswordResetToken> PasswordResetTokens { get; }  // ✅ NEW
    IRepository<EmailVerificationToken> EmailVerificationTokens { get; }
    IChildRepository Children { get; }
    IVoiceNoteRepository VoiceNotes { get; }
    IRepository<VaccinationMilestone> VaccinationMilestones { get; }
    IRepository<ChildVaccination> ChildVaccinations { get; }
    IRepository<Specialist> Specialists { get; }
    IRepository<VaccinationAppointment> VaccinationAppointments { get; }  // ✅ Vaccination Reminders
    IRepository<TaskCategory> TaskCategories { get; }  // ✅ Task Feature
    IRepository<ParentTask> Tasks { get; }             // ✅ Task Feature
    IRepository<TaskAssignee> TaskAssignees { get; }   // ✅ Task Feature
    IRepository<HealthUnit> HealthUnits { get; }       // ✅ Health Unit Search Feature
    IRepository<ChildTask> ChildTasks { get; }                      // ✅ Child Tasks Feature
    IRepository<ChildTaskAssignee> ChildTaskAssignees { get; }     // ✅ Child Tasks Feature
    IRepository<ChildTaskRecurrence> ChildTaskRecurrences { get; } // ✅ Child Tasks Feature
    IRepository<Prize> Prizes { get; }
    IRepository<PrizeTask> PrizeTasks { get; }
    IRepository<DailyQuestion> DailyQuestions { get; }
    IRepository<DailyQuestionOption> DailyQuestionOptions { get; }
    IRepository<DailyQuestionAnswer> DailyQuestionAnswers { get; }
    IRepository<SpecialistStatusHistory> SpecialistStatusHistories { get; }
    IRepository<Specialty> Specialties { get; }
    IRepository<LessonCategory> LessonCategories { get; }         // ✅ Lesson Feature
    IRepository<Lesson> Lessons { get; }                          // ✅ Lesson Feature
    IRepository<LessonQuestion> LessonQuestions { get; }          // ✅ Lesson Feature
    IRepository<LessonQuestionOption> LessonQuestionOptions { get; } // ✅ Lesson Feature
    IRepository<LessonProgress> LessonProgresses { get; }         // ✅ Lesson Feature
    IRepository<LessonQuestionAnswer> LessonQuestionAnswers { get; } // ✅ Lesson Feature
    IRepository<RankingCycle> RankingCycles { get; }                // ✅ Ranking Feature
    IRepository<RankingEntry> RankingEntries { get; }               // ✅ Ranking Feature
    IRepository<Clinic> Clinics { get; }                            // ✅ Clinic Feature
    IRepository<RemoteConsultation> RemoteConsultations { get; }    // ✅ Remote Consultation Feature
    IRepository<Booking> Bookings { get; }                          // ✅ Consultation Booking Feature
    IRepository<BookingAttachment> BookingAttachments { get; }      // ✅ Consultation Booking Feature
    IRepository<Payment> Payments { get; }                          // ✅ Consultation Booking Feature
    IRepository<PaymentSetting> PaymentSettings { get; }            // ✅ Consultation Booking Feature
    IRepository<PrescriptionMedicine> PrescriptionMedicines { get; } // ✅ Doctor Consultation — الروشتة الطبية
    IRepository<MedicalDiagnosis> MedicalDiagnoses { get; }          // ✅ Doctor Consultation — التشخيص الطبي
    Task<int> SaveChangesAsync();
    Task BeginTransactionAsync();
    Task CommitTransactionAsync();
    Task RollbackTransactionAsync();
    Task ExecuteInTransactionAsync(Func<Task> operation);
    Task<int> SaveAsync();
}
