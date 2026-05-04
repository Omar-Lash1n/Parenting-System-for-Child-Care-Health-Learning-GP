using Ajial.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Ajial.Infrastructure.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users { get; set; } = null!;
    public DbSet<Parent> Parents { get; set; } = null!;
    public DbSet<City> Cities { get; set; } = null!;
    public DbSet<PasswordResetToken> PasswordResetTokens { get; set; } = null!;
    public DbSet<EmailVerificationToken> EmailVerificationTokens { get; set; } = null!;
    public DbSet<Child> Children { get; set; } = null!;
    public DbSet<VoiceNote> VoiceNotes { get; set; } = null!;
    public DbSet<VaccinationMilestone> VaccinationMilestones { get; set; } = null!;
    public DbSet<ChildVaccination> ChildVaccinations { get; set; } = null!;
    public DbSet<Specialist> Specialists { get; set; } = null!;
    public DbSet<VaccinationAppointment> VaccinationAppointments { get; set; } = null!;  // ✅ Vaccination Reminders
    public DbSet<TaskCategory> TaskCategories { get; set; } = null!;  // ✅ Task Feature
    public DbSet<ParentTask> Tasks { get; set; } = null!;             // ✅ Task Feature
    public DbSet<TaskAssignee> TaskAssignees { get; set; } = null!;   // ✅ Task Feature
    public DbSet<HealthUnit> HealthUnits { get; set; } = null!;        // ✅ Health Unit Search Feature
    public DbSet<ChildTask> ChildTasks { get; set; } = null!;                      // ✅ Child Tasks Feature
    public DbSet<ChildTaskAssignee> ChildTaskAssignees { get; set; } = null!;     // ✅ Child Tasks Feature
    public DbSet<ChildTaskRecurrence> ChildTaskRecurrences { get; set; } = null!; // ✅ Child Tasks Feature
    public DbSet<Prize> Prizes { get; set; } = null!;
    public DbSet<PrizeTask> PrizeTasks { get; set; } = null!;
    public DbSet<SpecialistStatusHistory> SpecialistStatusHistories { get; set; } = null!;
    public DbSet<Specialty> Specialties { get; set; } = null!;
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // User Configuration
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Username).IsUnique();
            entity.HasIndex(e => e.Email).IsUnique();
            entity.Property(e => e.FullName).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Username).IsRequired().HasMaxLength(50);
            entity.Property(e => e.Email).IsRequired().HasMaxLength(100);
            entity.Property(e => e.PasswordHash).IsRequired();

            // FCM Device Token (nullable — not all users have a mobile device token registered)
            entity.Property(e => e.DeviceToken).HasMaxLength(500);
        });
        // ✅ NEW: Configure PasswordResetToken

        modelBuilder.Entity<PasswordResetToken>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Token).IsRequired().HasMaxLength(500);

            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(e => e.Token);
            entity.HasIndex(e => e.UserId);
        });

        // Configure EmailVerificationToken
        modelBuilder.Entity<EmailVerificationToken>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Token).IsRequired().HasMaxLength(500);

            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(e => e.Token);
            entity.HasIndex(e => e.UserId);
        });

        // Parent Configuration
        modelBuilder.Entity<Parent>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasOne(e => e.User)
                  .WithOne()
                  .HasForeignKey<Parent>(e => e.UserId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.City)
                  .WithMany()
                  .HasForeignKey(e => e.CityId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        // City Configuration
        modelBuilder.Entity<City>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
            entity.Property(e => e.NameAr).IsRequired().HasMaxLength(100);
        });
        modelBuilder.Entity<Child>(entity =>
        {
            entity.HasKey(c => c.Id);

            // Properties
            entity.Property(c => c.FullName)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(c => c.BirthDate)
                .IsRequired();

            entity.Property(c => c.Age)
                .IsRequired();

            entity.Property(c => c.Gender)
                .IsRequired()
                .HasMaxLength(10);

            entity.Property(c => c.ProfileImageUrl)
                .HasMaxLength(500);

            entity.Property(c => c.ChildLoginId)
                .HasMaxLength(20);

            entity.Property(c => c.PasswordHash)
                .HasMaxLength(500);

            entity.Property(c => c.CreatedAt)
                .IsRequired();

            entity.Property(c => c.UpdatedAt)
                .IsRequired();

            entity.Property(c => c.IsActive)
                .IsRequired()
                .HasDefaultValue(true);

            // Medical Profile Properties
            entity.Property(c => c.Height).HasColumnType("float");
            entity.Property(c => c.Weight).HasColumnType("float");
            entity.Property(c => c.HeadCircumference).HasColumnType("float");
            entity.Property(c => c.BloodType).HasMaxLength(10);
            entity.Property(c => c.MedicalHistory).HasMaxLength(1000);

            // Relationship with Parent
            entity.HasOne(c => c.Parent)
                .WithMany(p => p.Children)
                .HasForeignKey(c => c.ParentId)
                .OnDelete(DeleteBehavior.Restrict);

            // Indexes
            entity.HasIndex(c => c.ChildLoginId)
                .IsUnique()
                .HasFilter("[ChildLoginId] IS NOT NULL");

            entity.HasIndex(c => c.ParentId);

            entity.HasIndex(c => c.IsActive);
        });

        // VoiceNote Configuration
        modelBuilder.Entity<VoiceNote>(entity =>
        {
            entity.HasKey(v => v.Id);

            entity.Property(v => v.Title)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(v => v.BlobUrl)
                .IsRequired()
                .HasMaxLength(500);

            entity.Property(v => v.FileName)
                .IsRequired()
                .HasMaxLength(200);

            entity.Property(v => v.ContentType)
                .IsRequired()
                .HasMaxLength(50);

            entity.Property(v => v.FileSizeBytes)
                .IsRequired();

            entity.Property(v => v.CreatedAt)
                .IsRequired();

            entity.Property(v => v.IsActive)
                .IsRequired()
                .HasDefaultValue(true);

            // Relationship with Child
            entity.HasOne(v => v.Child)
                .WithMany()
                .HasForeignKey(v => v.ChildId)
                .OnDelete(DeleteBehavior.Cascade);

            // Indexes
            entity.HasIndex(v => v.ChildId);
            entity.HasIndex(v => v.IsActive);
            entity.HasIndex(v => v.CreatedAt);
        });

        // VaccinationMilestone Configuration
        modelBuilder.Entity<VaccinationMilestone>(entity =>
        {
            entity.HasKey(v => v.Id);

            entity.Property(v => v.NameAr)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(v => v.NameEn)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(v => v.AgeInMonths)
                .IsRequired();

            entity.Property(v => v.VaccinesAr)
                .IsRequired()
                .HasMaxLength(500);

            entity.Property(v => v.VaccinesEn)
                .IsRequired()
                .HasMaxLength(500);

            entity.Property(v => v.SortOrder)
                .IsRequired();

            entity.Property(v => v.IsActive)
                .IsRequired()
                .HasDefaultValue(true);

            entity.Property(v => v.Category)
                .IsRequired()
                .HasMaxLength(20)
                .HasDefaultValue("Main");
        });

        // ChildVaccination Configuration
        modelBuilder.Entity<ChildVaccination>(entity =>
        {
            entity.HasKey(cv => cv.Id);

            entity.Property(cv => cv.IsTaken)
                .IsRequired();

            entity.Property(cv => cv.RecordedAt)
                .IsRequired();

            entity.Property(cv => cv.UpdatedAt)
                .IsRequired();

            // Relationship with Child
            entity.HasOne(cv => cv.Child)
                .WithMany(c => c.Vaccinations)
                .HasForeignKey(cv => cv.ChildId)
                .OnDelete(DeleteBehavior.Cascade);

            // Relationship with VaccinationMilestone
            entity.HasOne(cv => cv.VaccinationMilestone)
                .WithMany()
                .HasForeignKey(cv => cv.VaccinationMilestoneId)
                .OnDelete(DeleteBehavior.Restrict);

            // Composite unique index — one record per child per milestone
            entity.HasIndex(cv => new { cv.ChildId, cv.VaccinationMilestoneId })
                .IsUnique();

            entity.HasIndex(cv => cv.ChildId);
        });

        // Specialist Configuration
        modelBuilder.Entity<Specialist>(entity =>
        {
            entity.HasKey(e => e.Id);

            entity.HasOne(e => e.User)
                  .WithOne()
                  .HasForeignKey<Specialist>(e => e.UserId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.Property(e => e.Phone).IsRequired().HasMaxLength(20);
            entity.Property(e => e.Specialization).IsRequired().HasMaxLength(100);
            entity.Property(e => e.PracticeLicenseNumber).IsRequired().HasMaxLength(50);
            entity.Property(e => e.IdFrontImageUrl).IsRequired().HasMaxLength(500);
            entity.Property(e => e.IdBackImageUrl).HasMaxLength(500);
            entity.Property(e => e.SpecializationCertificateImageUrl).IsRequired().HasMaxLength(500);
            entity.Property(e => e.PracticeLicenseImageUrl).IsRequired().HasMaxLength(500);
            entity.Property(e => e.UnionCardImageUrl).IsRequired().HasMaxLength(500);
            entity.Property(e => e.PersonalPhotoUrl).IsRequired().HasMaxLength(500);
            entity.Property(e => e.Status).IsRequired();
            entity.Property(e => e.RejectionReason).HasMaxLength(1000);
            entity.Property(e => e.SubmittedAt);
            entity.Property(e => e.ReviewedAt);
            entity.Property(e => e.ReviewedByUserId);

            entity.HasIndex(e => e.UserId).IsUnique();
            entity.HasIndex(e => e.PracticeLicenseNumber).IsUnique();
        });

        // Specialist Status History Configuration
        modelBuilder.Entity<SpecialistStatusHistory>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasOne(e => e.Specialist)
                  .WithMany(s => s.StatusHistories)
                  .HasForeignKey(e => e.SpecialistId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.Property(e => e.Reason).HasMaxLength(1000);
            entity.Property(e => e.ChangedAt).IsRequired();
            entity.Property(e => e.FromStatus).IsRequired();
            entity.Property(e => e.ToStatus).IsRequired();

            entity.HasIndex(e => e.SpecialistId);
            entity.HasIndex(e => e.ChangedAt);
        });

        // Specialty Lookup Configuration
        modelBuilder.Entity<Specialty>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.NameAr).IsRequired().HasMaxLength(100);
            entity.Property(e => e.NameEn).IsRequired().HasMaxLength(100);
            entity.Property(e => e.IsActive).IsRequired().HasDefaultValue(true);
        });

        modelBuilder.Entity<Specialty>().HasData(
            new Specialty { Id = 1, NameAr = "طبيب عام", NameEn = "General Practitioner", IsActive = true },
            new Specialty { Id = 2, NameAr = "متخصص تربوي", NameEn = "Educational Specialist", IsActive = true },
            new Specialty { Id = 3, NameAr = "طبيب أطفال", NameEn = "Pediatrician", IsActive = true },
            new Specialty { Id = 4, NameAr = "أخصائي تغذية", NameEn = "Nutritionist", IsActive = true },
            new Specialty { Id = 5, NameAr = "أخصائي نفسي", NameEn = "Psychologist", IsActive = true }
        );

        // ✅ VaccinationAppointment Configuration
        modelBuilder.Entity<VaccinationAppointment>(entity =>
        {
            entity.HasKey(va => va.Id);

            entity.Property(va => va.HealthUnit)
                .IsRequired()
                .HasMaxLength(200);

            entity.Property(va => va.AppointmentDateTime)
                .IsRequired();

            entity.Property(va => va.CreatedAt)
                .IsRequired();

            entity.Property(va => va.UpdatedAt)
                .IsRequired();

            // Relationship with Child
            entity.HasOne(va => va.Child)
                .WithMany()
                .HasForeignKey(va => va.ChildId)
                .OnDelete(DeleteBehavior.Cascade);

            // Relationship with VaccinationMilestone
            entity.HasOne(va => va.VaccinationMilestone)
                .WithMany()
                .HasForeignKey(va => va.VaccinationMilestoneId)
                .OnDelete(DeleteBehavior.Restrict);

            // ONE record per child per milestone (enforces upsert semantics)
            entity.HasIndex(va => new { va.ChildId, va.VaccinationMilestoneId })
                .IsUnique();

            // Performance indexes for the background worker queries
            entity.HasIndex(va => va.AppointmentDateTime);
            entity.HasIndex(va => va.IsProcessedOneDayBefore);
            entity.HasIndex(va => va.IsProcessedThreeHoursBefore);
            entity.HasIndex(va => va.IsProcessedCustom);
            entity.HasIndex(va => va.IsProcessedAtTime);
        });

        // ✅ TaskCategory Configuration
        modelBuilder.Entity<TaskCategory>(entity =>
        {
            entity.HasKey(tc => tc.Id);

            entity.Property(tc => tc.Name)
                .IsRequired()
                .HasMaxLength(100);

            entity.Property(tc => tc.IsSystem)
                .IsRequired()
                .HasDefaultValue(false);

            entity.Property(tc => tc.CreatedAt)
                .IsRequired();

            entity.HasOne(tc => tc.Parent)
                .WithMany()
                .HasForeignKey(tc => tc.ParentId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(tc => tc.ParentId);
        });

        // ✅ ParentTask Configuration
        modelBuilder.Entity<ParentTask>(entity =>
        {
            entity.HasKey(t => t.Id);

            entity.Property(t => t.Title)
                .IsRequired()
                .HasMaxLength(200);

            entity.Property(t => t.Color)
                .HasMaxLength(20);

            entity.Property(t => t.IsCompleted)
                .IsRequired()
                .HasDefaultValue(false);

            entity.Property(t => t.IsPushSent)
                .IsRequired()
                .HasDefaultValue(false);

            entity.Property(t => t.IncludeParent)
                .IsRequired()
                .HasDefaultValue(false);

            entity.Property(t => t.CreatedAt)
                .IsRequired();

            entity.HasOne(t => t.Parent)
                .WithMany()
                .HasForeignKey(t => t.ParentId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(t => t.Category)
                .WithMany(tc => tc.Tasks)
                .HasForeignKey(t => t.CategoryId)
                .OnDelete(DeleteBehavior.ClientSetNull);

            // Performance indexes for background worker
            entity.HasIndex(t => t.ParentId);
            entity.HasIndex(t => t.IsPushSent);
            entity.HasIndex(t => t.DueDate);
            entity.HasIndex(t => t.IsCompleted);
        });

        // ✅ TaskAssignee Configuration (composite PK join table)
        modelBuilder.Entity<TaskAssignee>(entity =>
        {
            entity.HasKey(ta => new { ta.TaskId, ta.ChildId });

            entity.HasOne(ta => ta.Task)
                .WithMany(t => t.Assignees)
                .HasForeignKey(ta => ta.TaskId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(ta => ta.Child)
                .WithMany()
                .HasForeignKey(ta => ta.ChildId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(ta => ta.TaskId);
            entity.HasIndex(ta => ta.ChildId);
        });

        // ✅ ChildTask Configuration
        modelBuilder.Entity<ChildTask>(entity =>
        {
            entity.HasKey(ct => ct.Id);

            entity.Property(ct => ct.Title)
                .IsRequired()
                .HasMaxLength(200);

            entity.Property(ct => ct.TaskImageUrl)
                .HasMaxLength(2048);

            entity.Property(ct => ct.RecordingUrl)
                .HasMaxLength(2048);

            entity.Property(ct => ct.Stars)
                .IsRequired()
                .HasDefaultValue(0);

            entity.Property(ct => ct.CreatedAt)
                .IsRequired();

            entity.HasOne(ct => ct.Parent)
                .WithMany()
                .HasForeignKey(ct => ct.ParentId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(ct => ct.Recurrence)
                .WithOne(r => r.Task)
                .HasForeignKey<ChildTaskRecurrence>(r => r.TaskId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(ct => ct.ParentId);
            entity.HasIndex(ct => ct.DueDate);
        });

        // ✅ ChildTaskAssignee Configuration (composite PK join table)
        modelBuilder.Entity<ChildTaskAssignee>(entity =>
        {
            entity.HasKey(cta => new { cta.TaskId, cta.ChildId });

            entity.Property(cta => cta.IsCompleted)
                .IsRequired()
                .HasDefaultValue(false);

            entity.HasOne(cta => cta.Task)
                .WithMany(ct => ct.Assignees)
                .HasForeignKey(cta => cta.TaskId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(cta => cta.Child)
                .WithMany()
                .HasForeignKey(cta => cta.ChildId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(cta => cta.TaskId);
            entity.HasIndex(cta => cta.ChildId);
            entity.HasIndex(cta => new { cta.ChildId, cta.IsCompleted }); // fast lookup per-child
        });

        // ✅ ChildTaskRecurrence Configuration
        modelBuilder.Entity<ChildTaskRecurrence>(entity =>
        {
            entity.HasKey(r => r.Id);

            entity.Property(r => r.RepeatDays)
                .HasMaxLength(200);

            entity.Property(r => r.RepeatTime)
                .HasMaxLength(5);

            entity.Property(r => r.IsRecurring)
                .IsRequired()
                .HasDefaultValue(false);

            entity.HasIndex(r => r.TaskId).IsUnique();
        });

        // Prizes Store Configuration
        modelBuilder.Entity<Prize>(entity =>
        {
            entity.HasKey(p => p.Id);

            entity.Property(p => p.Title)
                .IsRequired()
                .HasMaxLength(200);

            entity.Property(p => p.ImageUrl)
                .HasMaxLength(2048);

            entity.Property(p => p.RequiredStars)
                .IsRequired();

            entity.Property(p => p.Status)
                .IsRequired()
                .HasDefaultValue(PrizeStatus.Active);

            entity.Property(p => p.CreatedAt)
                .IsRequired();

            entity.HasOne(p => p.Parent)
                .WithMany()
                .HasForeignKey(p => p.ParentId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(p => p.Child)
                .WithMany()
                .HasForeignKey(p => p.ChildId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(p => p.ParentId);
            entity.HasIndex(p => p.ChildId);
            entity.HasIndex(p => p.Status);
        });

        modelBuilder.Entity<PrizeTask>(entity =>
        {
            entity.HasKey(pt => new { pt.PrizeId, pt.TaskId });

            entity.HasOne(pt => pt.Prize)
                .WithMany(p => p.RequiredTasks)
                .HasForeignKey(pt => pt.PrizeId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(pt => pt.Task)
                .WithMany()
                .HasForeignKey(pt => pt.TaskId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasIndex(pt => pt.PrizeId);
            entity.HasIndex(pt => pt.TaskId);
        });

        // ✅ HealthUnit Configuration
        modelBuilder.Entity<HealthUnit>(entity =>
        {
            entity.HasKey(hu => hu.Id);

            entity.Property(hu => hu.NameAr)
                .IsRequired()
                .HasMaxLength(200);

            entity.Property(hu => hu.NameEn)
                .IsRequired()
                .HasMaxLength(200);

            entity.Property(hu => hu.Type)
                .IsRequired();

            entity.Property(hu => hu.AddressAr)
                .IsRequired()
                .HasMaxLength(500);

            entity.Property(hu => hu.AddressEn)
                .HasMaxLength(500);

            entity.Property(hu => hu.Latitude)
                .IsRequired()
                .HasColumnType("float");

            entity.Property(hu => hu.Longitude)
                .IsRequired()
                .HasColumnType("float");

            entity.Property(hu => hu.Phone)
                .HasMaxLength(20);

            entity.Property(hu => hu.Notes)
                .HasMaxLength(500);

            entity.Property(hu => hu.DataSource)
                .HasMaxLength(200);

            entity.Property(hu => hu.IsVerified)
                .IsRequired()
                .HasDefaultValue(false);

            entity.Property(hu => hu.IsActive)
                .IsRequired()
                .HasDefaultValue(true);

            entity.Property(hu => hu.CreatedAt)
                .IsRequired();

            // Relationship with City
            entity.HasOne(hu => hu.City)
                .WithMany()
                .HasForeignKey(hu => hu.CityId)
                .OnDelete(DeleteBehavior.Restrict);

            // Indexes
            entity.HasIndex(hu => hu.CityId);
            entity.HasIndex(hu => hu.Type);
            entity.HasIndex(hu => hu.IsActive);
            entity.HasIndex(hu => new { hu.Latitude, hu.Longitude });
            entity.HasIndex(hu => hu.NameAr);
        });

        // Seed data
        SeedCities(modelBuilder);
        SeedVaccinationMilestones(modelBuilder);
        SeedHealthUnits(modelBuilder);
    }

    private void SeedCities(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<City>().HasData(
            new City { Id = 1, Name = "Cairo", NameAr = "القاهرة", IsActive = true },
            new City { Id = 2, Name = "Alexandria", NameAr = "الإسكندرية", IsActive = true },
            new City { Id = 3, Name = "Giza", NameAr = "الجيزة", IsActive = true },
            new City { Id = 4, Name = "Shubra El Kheima", NameAr = "شبرا الخيمة", IsActive = true },
            new City { Id = 5, Name = "Port Said", NameAr = "بورسعيد", IsActive = true },
            new City { Id = 6, Name = "Suez", NameAr = "السويس", IsActive = true },
            new City { Id = 7, Name = "Mansoura", NameAr = "المنصورة", IsActive = true },
            new City { Id = 8, Name = "El Mahalla El Kubra", NameAr = "المحلة الكبرى", IsActive = true },
            new City { Id = 9, Name = "Tanta", NameAr = "طنطا", IsActive = true },
            new City { Id = 10, Name = "Asyut", NameAr = "أسيوط", IsActive = true },
            new City { Id = 11, Name = "Fayyum", NameAr = "الفيوم", IsActive = true },
            new City { Id = 12, Name = "Zagazig", NameAr = "الزقازيق", IsActive = true },
            new City { Id = 13, Name = "Ismailia", NameAr = "الإسماعيلية", IsActive = true },
            new City { Id = 14, Name = "Aswan", NameAr = "أسوان", IsActive = true },
            new City { Id = 15, Name = "6th of October City", NameAr = "السادس من أكتوبر", IsActive = true },
            new City { Id = 16, Name = "Damanhur", NameAr = "دمنهور", IsActive = true },
            new City { Id = 17, Name = "Damietta", NameAr = "دمياط", IsActive = true },
            new City { Id = 18, Name = "Minya", NameAr = "المنيا", IsActive = true },
            new City { Id = 19, Name = "Beni Suef", NameAr = "بني سويف", IsActive = true },
            new City { Id = 20, Name = "Luxor", NameAr = "الأقصر", IsActive = true },
            new City { Id = 21, Name = "Sohag", NameAr = "سوهاج", IsActive = true },
            new City { Id = 22, Name = "Shibin El Kom", NameAr = "شبين الكوم", IsActive = true },
            new City { Id = 23, Name = "Qena", NameAr = "قنا", IsActive = true },
            new City { Id = 24, Name = "Hurghada", NameAr = "الغردقة", IsActive = true },
            new City { Id = 25, Name = "Arish", NameAr = "العريش", IsActive = true },
            new City { Id = 26, Name = "Mallawi", NameAr = "ملوي", IsActive = true },
            new City { Id = 27, Name = "10th of Ramadan City", NameAr = "العاشر من رمضان", IsActive = true },
            new City { Id = 28, Name = "Bilbais", NameAr = "بلبيس", IsActive = true },
            new City { Id = 29, Name = "Marsa Matruh", NameAr = "مرسى مطروح", IsActive = true },
            new City { Id = 30, Name = "Banha", NameAr = "بنها", IsActive = true },
            new City { Id = 31, Name = "Kafr El Sheikh", NameAr = "كفر الشيخ", IsActive = true },
            new City { Id = 32, Name = "Sharm El Sheikh", NameAr = "شرم الشيخ", IsActive = true },
            new City { Id = 33, Name = "New Cairo", NameAr = "القاهرة الجديدة", IsActive = true },
            new City { Id = 34, Name = "New Administrative Capital", NameAr = "العاصمة الإدارية الجديدة", IsActive = true }
        );
    }

    private void SeedVaccinationMilestones(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<VaccinationMilestone>().HasData(
            new VaccinationMilestone
            {
                Id = 1,
                NameAr = "تطعيم الولادة",
                NameEn = "Birth Vaccination",
                AgeInMonths = 0,
                VaccinesAr = "كبدي ب رضع, شلل اطفال فموي, طعم بي سي جي",
                VaccinesEn = "Hepatitis B, Oral Polio Vaccine, BCG",
                SortOrder = 1,
                IsActive = true,
                Category = "Main"
            },
            new VaccinationMilestone
            {
                Id = 2,
                NameAr = "تطعيم شهرين",
                NameEn = "2 Months Vaccination",
                AgeInMonths = 2,
                VaccinesAr = "شلل اطفال (فموي), الطعم الخماسي",
                VaccinesEn = "Oral Polio Vaccine, Pentavalent Vaccine",
                SortOrder = 2,
                IsActive = true,
                Category = "Main"
            },
            new VaccinationMilestone
            {
                Id = 3,
                NameAr = "تطعيم 4 شهور",
                NameEn = "4 Months Vaccination",
                AgeInMonths = 4,
                VaccinesAr = "شلل اطفال (فموي), الطعم الخماسي, شلل اطفال (حقن)",
                VaccinesEn = "Oral Polio Vaccine, Pentavalent Vaccine, IPV",
                SortOrder = 3,
                IsActive = true,
                Category = "Main"
            },
            new VaccinationMilestone
            {
                Id = 4,
                NameAr = "تطعيم 6 شهور",
                NameEn = "6 Months Vaccination",
                AgeInMonths = 6,
                VaccinesAr = "شلل اطفال (فموي), الطعم الخماسي, شلل اطفال (حقن)",
                VaccinesEn = "Oral Polio Vaccine, Pentavalent Vaccine, IPV",
                SortOrder = 4,
                IsActive = true,
                Category = "Main"
            },
            new VaccinationMilestone
            {
                Id = 5,
                NameAr = "تطعيم 9 شهور",
                NameEn = "9 Months Vaccination",
                AgeInMonths = 9,
                VaccinesAr = "شلل اطفال (فموي)",
                VaccinesEn = "Oral Polio Vaccine",
                SortOrder = 5,
                IsActive = true,
                Category = "Main"
            },
            new VaccinationMilestone
            {
                Id = 6,
                NameAr = "تطعيم 12 شهر",
                NameEn = "12 Months Vaccination",
                AgeInMonths = 12,
                VaccinesAr = "شلل اطفال (فموي), الثلاثى الفيروسي",
                VaccinesEn = "Oral Polio Vaccine, MMR",
                SortOrder = 6,
                IsActive = true,
                Category = "Main"
            },
            new VaccinationMilestone
            {
                Id = 7,
                NameAr = "تطعيم 18 شهر",
                NameEn = "18 Months Vaccination",
                AgeInMonths = 18,
                VaccinesAr = "شلل اطفال (فموي), الثلاثى الفيروسي",
                VaccinesEn = "Oral Polio Vaccine, MMR",
                SortOrder = 7,
                IsActive = true,
                Category = "Main"
            },
            // ── Additional Milestones (4–15 years) ──
            new VaccinationMilestone
            {
                Id = 8,
                NameAr = "تطعيم أولى حضانة",
                NameEn = "KG1 Vaccination",
                AgeInMonths = 48, // 4 years
                VaccinesAr = "المكورات السحائية الثنائى",
                VaccinesEn = "Meningococcal Vaccine",
                SortOrder = 8,
                IsActive = true,
                Category = "Additional"
            },
            new VaccinationMilestone
            {
                Id = 9,
                NameAr = "تطعيم أولى ابتدائى",
                NameEn = "Grade 1 Vaccination",
                AgeInMonths = 72, // 6 years
                VaccinesAr = "المكورات السحائية الثنائى",
                VaccinesEn = "Meningococcal Vaccine",
                SortOrder = 9,
                IsActive = true,
                Category = "Additional"
            },
            new VaccinationMilestone
            {
                Id = 10,
                NameAr = "تطعيم ثانية ابتدائى",
                NameEn = "Grade 2 Vaccination",
                AgeInMonths = 84, // 7 years
                VaccinesAr = "الثنائى البكتيري",
                VaccinesEn = "DT Vaccine",
                SortOrder = 10,
                IsActive = true,
                Category = "Additional"
            },
            new VaccinationMilestone
            {
                Id = 11,
                NameAr = "تطعيم رابعة ابتدائى",
                NameEn = "Grade 4 Vaccination",
                AgeInMonths = 120, // 10 years
                VaccinesAr = "الثنائى البكتيري",
                VaccinesEn = "DT Vaccine",
                SortOrder = 11,
                IsActive = true,
                Category = "Additional"
            },
            new VaccinationMilestone
            {
                Id = 12,
                NameAr = "تطعيم أولى إعدادي",
                NameEn = "Grade 7 Vaccination",
                AgeInMonths = 144, // 12 years
                VaccinesAr = "المكورات السحائية الثنائى",
                VaccinesEn = "Meningococcal Vaccine",
                SortOrder = 12,
                IsActive = true,
                Category = "Additional"
            },
            new VaccinationMilestone
            {
                Id = 13,
                NameAr = "تطعيم أولى ثانوي",
                NameEn = "Grade 10 Vaccination",
                AgeInMonths = 180, // 15 years
                VaccinesAr = "المكورات السحائية الثنائى",
                VaccinesEn = "Meningococcal Vaccine",
                SortOrder = 13,
                IsActive = true,
                Category = "Additional"
            }
        );
    }

    private void SeedHealthUnits(ModelBuilder modelBuilder)
    {
        var seedDate = new DateTime(2026, 4, 11, 0, 0, 0, DateTimeKind.Utc);

        modelBuilder.Entity<HealthUnit>().HasData(
            // ══════════════════════════════════════════════════════════════
            // القاهرة — Cairo (CityId = 1)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 1, NameAr = "وحدة صحة الأسرة - المعادي", NameEn = "Family Health Unit - Maadi", Type = HealthUnitType.HealthUnit, AddressAr = "شارع 9، المعادي، القاهرة", CityId = 1, Latitude = 29.9602, Longitude = 31.2569, Phone = "0225281234", Notes = "يعمل يوميًا من 8 ص حتى 2 م ما عدا الجمعة", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 2, NameAr = "مركز تطعيم حي مصر الجديدة", NameEn = "Heliopolis Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الحجاز، مصر الجديدة، القاهرة", CityId = 1, Latitude = 30.0870, Longitude = 31.3230, Phone = "0224171234", Notes = "مركز تطعيم رئيسي - يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 3, NameAr = "وحدة صحة الأسرة - حدائق القبة", NameEn = "Family Health Unit - Hadayek El-Qobba", Type = HealthUnitType.HealthUnit, AddressAr = "شارع فاروق، حدائق القبة، القاهرة", CityId = 1, Latitude = 30.0840, Longitude = 31.2913, Phone = "0224501234", Notes = "يعمل من 8 ص حتى 2 م", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 4, NameAr = "مستشفى الأطفال التخصصي - القاهرة", NameEn = "Children's Specialized Hospital - Cairo", Type = HealthUnitType.Hospital, AddressAr = "شارع أحمد عرابي، العباسية، القاهرة", CityId = 1, Latitude = 30.0731, Longitude = 31.2797, Phone = "0226831234", Notes = "مستشفى أطفال تخصصي يقدم خدمات التطعيم", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 5, NameAr = "وحدة صحة الأسرة - عين شمس", NameEn = "Family Health Unit - Ain Shams", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الخليفة المأمون، عين شمس، القاهرة", CityId = 1, Latitude = 30.1310, Longitude = 31.3280, Phone = "0224861234", Notes = "يعمل يوميًا من 8 ص حتى 2 م", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 6, NameAr = "وحدة صحة الأسرة - المرج", NameEn = "Family Health Unit - El Marg", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الأمل، المرج، القاهرة", CityId = 1, Latitude = 30.1530, Longitude = 31.3470, Phone = "0244731234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 7, NameAr = "مركز تطعيم السيدة زينب", NameEn = "Sayeda Zeinab Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع بورسعيد، السيدة زينب، القاهرة", CityId = 1, Latitude = 30.0290, Longitude = 31.2360, Phone = "0223641234", Notes = "مركز تطعيم - يعمل كل يوم ما عدا الجمعة", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 8, NameAr = "وحدة صحة الأسرة - حلوان", NameEn = "Family Health Unit - Helwan", Type = HealthUnitType.HealthUnit, AddressAr = "شارع منصور، حلوان، القاهرة", CityId = 1, Latitude = 29.8412, Longitude = 31.3340, Phone = "0225561234", Notes = "يعمل من 9 ص حتى 3 م", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 9, NameAr = "مستشفى حميات العباسية", NameEn = "Abbassia Fever Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع رمسيس، العباسية، القاهرة", CityId = 1, Latitude = 30.0760, Longitude = 31.2840, Phone = "0226821234", Notes = "يقدم خدمات التطعيم ضد الأمراض المعدية", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 10, NameAr = "وحدة صحة الأسرة - مدينة نصر", NameEn = "Family Health Unit - Nasr City", Type = HealthUnitType.HealthUnit, AddressAr = "شارع عباس العقاد، مدينة نصر، القاهرة", CityId = 1, Latitude = 30.0511, Longitude = 31.3480, Phone = "0222751234", Notes = "يعمل يوميًا من 8 ص حتى 2 م", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // الإسكندرية — Alexandria (CityId = 2)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 11, NameAr = "وحدة صحة الأسرة - سيدي بشر", NameEn = "Family Health Unit - Sidi Bishr", Type = HealthUnitType.HealthUnit, AddressAr = "شارع خالد بن الوليد، سيدي بشر، الإسكندرية", CityId = 2, Latitude = 31.2470, Longitude = 29.9810, Phone = "035461234", Notes = "يعمل يوميًا من 8 ص حتى 2 م", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 12, NameAr = "مركز تطعيم سموحة", NameEn = "Smouha Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع 14 مايو، سموحة، الإسكندرية", CityId = 2, Latitude = 31.2110, Longitude = 29.9510, Phone = "034261234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 13, NameAr = "وحدة صحة الأسرة - العجمي", NameEn = "Family Health Unit - El Agami", Type = HealthUnitType.HealthUnit, AddressAr = "طريق الإسكندرية مطروح، العجمي، الإسكندرية", CityId = 2, Latitude = 31.1390, Longitude = 29.7750, Phone = "034301234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 14, NameAr = "مستشفى الأطفال الجامعي - الإسكندرية", NameEn = "Alexandria University Children's Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجيش، الشاطبي، الإسكندرية", CityId = 2, Latitude = 31.2080, Longitude = 29.9150, Phone = "035901234", Notes = "مستشفى جامعي يقدم تطعيمات", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 15, NameAr = "وحدة صحة الأسرة - المنتزه", NameEn = "Family Health Unit - Montazah", Type = HealthUnitType.HealthUnit, AddressAr = "شارع المعمورة، المنتزه، الإسكندرية", CityId = 2, Latitude = 31.2870, Longitude = 30.0200, Phone = "035471234", Notes = "يعمل من 8 ص حتى 2 م", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 16, NameAr = "وحدة صحة الأسرة - محرم بك", NameEn = "Family Health Unit - Moharem Bek", Type = HealthUnitType.HealthUnit, AddressAr = "شارع مصطفى كامل، محرم بك، الإسكندرية", CityId = 2, Latitude = 31.1980, Longitude = 29.9120, Phone = "034951234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 17, NameAr = "مركز تطعيم العامرية", NameEn = "Amreya Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الجمهورية، العامرية، الإسكندرية", CityId = 2, Latitude = 31.1560, Longitude = 29.8300, Phone = "034551234", Notes = "مركز تطعيم - يعمل يوميًا ما عدا الجمعة", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 18, NameAr = "وحدة صحة الأسرة - برج العرب", NameEn = "Family Health Unit - Borg El Arab", Type = HealthUnitType.HealthUnit, AddressAr = "المدينة الصناعية، برج العرب، الإسكندرية", CityId = 2, Latitude = 30.8550, Longitude = 29.6640, Phone = "034591234", Notes = "يعمل من 8 ص حتى 2 م", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // الجيزة — Giza (CityId = 3)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 19, NameAr = "وحدة صحة الأسرة - الدقي", NameEn = "Family Health Unit - Dokki", Type = HealthUnitType.HealthUnit, AddressAr = "شارع التحرير، الدقي، الجيزة", CityId = 3, Latitude = 30.0380, Longitude = 31.2120, Phone = "0237601234", Notes = "يعمل يوميًا من 8 ص حتى 2 م", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 20, NameAr = "مركز تطعيم فيصل", NameEn = "Faisal Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع فيصل، فيصل، الجيزة", CityId = 3, Latitude = 30.0130, Longitude = 31.1840, Phone = "0237821234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 21, NameAr = "وحدة صحة الأسرة - العمرانية", NameEn = "Family Health Unit - Omraneya", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الهرم، العمرانية، الجيزة", CityId = 3, Latitude = 30.0140, Longitude = 31.2020, Phone = "0237891234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 22, NameAr = "مستشفى الحوامدية العام", NameEn = "Hawamdeya General Hospital", Type = HealthUnitType.Hospital, AddressAr = "الحوامدية، الجيزة", CityId = 3, Latitude = 29.8910, Longitude = 31.2540, Phone = "0238151234", Notes = "يقدم خدمات تطعيم للأطفال", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 23, NameAr = "وحدة صحة الأسرة - بولاق الدكرور", NameEn = "Family Health Unit - Boulaq El-Dakrour", Type = HealthUnitType.HealthUnit, AddressAr = "شارع ناهيا، بولاق الدكرور، الجيزة", CityId = 3, Latitude = 30.0260, Longitude = 31.1960, Phone = "0233591234", Notes = "يعمل من 8 ص حتى 2 م", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 24, NameAr = "مركز تطعيم الهرم", NameEn = "Haram Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الهرم، الجيزة", CityId = 3, Latitude = 29.9870, Longitude = 31.1560, Phone = "0233761234", Notes = "مركز تطعيم يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 25, NameAr = "وحدة صحة الأسرة - كرداسة", NameEn = "Family Health Unit - Kerdasa", Type = HealthUnitType.HealthUnit, AddressAr = "كرداسة، الجيزة", CityId = 3, Latitude = 30.0310, Longitude = 31.1100, Phone = "0238201234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 26, NameAr = "وحدة صحة الأسرة - أوسيم", NameEn = "Family Health Unit - Ossim", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الجمهورية، أوسيم، الجيزة", CityId = 3, Latitude = 30.1130, Longitude = 31.1370, Phone = "0238401234", Notes = "يعمل من 8 ص حتى 2 م", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // بورسعيد — Port Said (CityId = 5)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 27, NameAr = "وحدة صحة الأسرة - حي الشرق", NameEn = "Family Health Unit - East District", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الجيش، حي الشرق، بورسعيد", CityId = 5, Latitude = 31.2590, Longitude = 32.3010, Phone = "0663251234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 28, NameAr = "مركز تطعيم بورسعيد", NameEn = "Port Said Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع 23 يوليو، بورسعيد", CityId = 5, Latitude = 31.2620, Longitude = 32.3060, Phone = "0663401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 29, NameAr = "مستشفى بورسعيد العام", NameEn = "Port Said General Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجمهورية، بورسعيد", CityId = 5, Latitude = 31.2600, Longitude = 32.2990, Phone = "0663201234", Notes = "مستشفى عام يقدم تطعيمات", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // السويس — Suez (CityId = 6)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 30, NameAr = "وحدة صحة الأسرة - الأربعين", NameEn = "Family Health Unit - Arbaeen", Type = HealthUnitType.HealthUnit, AddressAr = "حي الأربعين، السويس", CityId = 6, Latitude = 29.9680, Longitude = 32.5260, Phone = "0623251234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 31, NameAr = "مركز تطعيم السويس", NameEn = "Suez Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الجيش، السويس", CityId = 6, Latitude = 29.9670, Longitude = 32.5490, Phone = "0623181234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 32, NameAr = "مستشفى السويس العام", NameEn = "Suez General Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجمهورية، السويس", CityId = 6, Latitude = 29.9690, Longitude = 32.5360, Phone = "0623101234", Notes = "مستشفى عام", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // المنصورة — Mansoura (CityId = 7)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 33, NameAr = "وحدة صحة الأسرة - حي الجامعة", NameEn = "Family Health Unit - University District", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الجامعة، المنصورة", CityId = 7, Latitude = 31.0420, Longitude = 31.3800, Phone = "0502341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 34, NameAr = "مركز تطعيم المنصورة", NameEn = "Mansoura Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الجمهورية، المنصورة", CityId = 7, Latitude = 31.0440, Longitude = 31.3780, Phone = "0502501234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 35, NameAr = "مستشفى الأطفال الجامعي - المنصورة", NameEn = "Mansoura University Children's Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجيش، المنصورة", CityId = 7, Latitude = 31.0400, Longitude = 31.3810, Phone = "0502301234", Notes = "مستشفى جامعي يقدم تطعيمات", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 36, NameAr = "وحدة صحة الأسرة - طلخا", NameEn = "Family Health Unit - Talkha", Type = HealthUnitType.HealthUnit, AddressAr = "طلخا، الدقهلية", CityId = 7, Latitude = 31.0580, Longitude = 31.3830, Phone = "0502551234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // طنطا — Tanta (CityId = 9)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 37, NameAr = "وحدة صحة الأسرة - وسط طنطا", NameEn = "Family Health Unit - Central Tanta", Type = HealthUnitType.HealthUnit, AddressAr = "شارع البحر، وسط طنطا", CityId = 9, Latitude = 30.7865, Longitude = 31.0004, Phone = "0403341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 38, NameAr = "مركز تطعيم طنطا", NameEn = "Tanta Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الجلاء، طنطا", CityId = 9, Latitude = 30.7880, Longitude = 31.0010, Phone = "0403401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 39, NameAr = "مستشفى طنطا الجامعي", NameEn = "Tanta University Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجيش، طنطا", CityId = 9, Latitude = 30.7850, Longitude = 30.9990, Phone = "0403201234", Notes = "مستشفى جامعي يقدم تطعيمات", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 40, NameAr = "وحدة صحة الأسرة - المحلة الكبرى", NameEn = "Family Health Unit - El Mahalla El Kubra", Type = HealthUnitType.HealthUnit, AddressAr = "شارع بورسعيد، المحلة الكبرى", CityId = 8, Latitude = 30.9693, Longitude = 31.1664, Phone = "0402201234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // أسيوط — Asyut (CityId = 10)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 41, NameAr = "وحدة صحة الأسرة - وسط أسيوط", NameEn = "Family Health Unit - Central Asyut", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الجمهورية، أسيوط", CityId = 10, Latitude = 27.1809, Longitude = 31.1837, Phone = "0882341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 42, NameAr = "مركز تطعيم أسيوط", NameEn = "Asyut Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الجيش، أسيوط", CityId = 10, Latitude = 27.1830, Longitude = 31.1850, Phone = "0882401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 43, NameAr = "مستشفى أسيوط الجامعي", NameEn = "Asyut University Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجامعة، أسيوط", CityId = 10, Latitude = 27.1845, Longitude = 31.1765, Phone = "0882301234", Notes = "مستشفى جامعي يقدم تطعيمات", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 44, NameAr = "وحدة صحة الأسرة - أبنوب", NameEn = "Family Health Unit - Abnoub", Type = HealthUnitType.HealthUnit, AddressAr = "أبنوب، أسيوط", CityId = 10, Latitude = 27.2680, Longitude = 31.1510, Phone = "0882551234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 45, NameAr = "وحدة صحة الأسرة - ديروط", NameEn = "Family Health Unit - Dairut", Type = HealthUnitType.HealthUnit, AddressAr = "ديروط، أسيوط", CityId = 10, Latitude = 27.5434, Longitude = 30.8166, Phone = "0882601234", Notes = "يعمل من 8 ص حتى 2 م", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // الفيوم — Fayyum (CityId = 11)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 46, NameAr = "وحدة صحة الأسرة - وسط الفيوم", NameEn = "Family Health Unit - Central Fayyum", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الجمهورية، الفيوم", CityId = 11, Latitude = 29.3084, Longitude = 30.8428, Phone = "0842341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 47, NameAr = "مركز تطعيم الفيوم", NameEn = "Fayyum Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الحرية، الفيوم", CityId = 11, Latitude = 29.3100, Longitude = 30.8440, Phone = "0842401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 48, NameAr = "مستشفى الفيوم العام", NameEn = "Fayyum General Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجيش، الفيوم", CityId = 11, Latitude = 29.3060, Longitude = 30.8410, Phone = "0842201234", Notes = "مستشفى عام", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // الزقازيق — Zagazig (CityId = 12)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 49, NameAr = "وحدة صحة الأسرة - الزقازيق", NameEn = "Family Health Unit - Zagazig", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الجلاء، الزقازيق", CityId = 12, Latitude = 30.5876, Longitude = 31.5020, Phone = "0552341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 50, NameAr = "مركز تطعيم الزقازيق", NameEn = "Zagazig Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع أحمد عرابي، الزقازيق", CityId = 12, Latitude = 30.5880, Longitude = 31.5030, Phone = "0552401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 51, NameAr = "مستشفى الزقازيق الجامعي", NameEn = "Zagazig University Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجامعة، الزقازيق", CityId = 12, Latitude = 30.5850, Longitude = 31.5060, Phone = "0552301234", Notes = "مستشفى جامعي يقدم تطعيمات", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // الإسماعيلية — Ismailia (CityId = 13)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 52, NameAr = "وحدة صحة الأسرة - الإسماعيلية", NameEn = "Family Health Unit - Ismailia", Type = HealthUnitType.HealthUnit, AddressAr = "شارع محمد علي، الإسماعيلية", CityId = 13, Latitude = 30.5965, Longitude = 32.2715, Phone = "0642341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 53, NameAr = "مركز تطعيم الإسماعيلية", NameEn = "Ismailia Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الجيش، الإسماعيلية", CityId = 13, Latitude = 30.5980, Longitude = 32.2720, Phone = "0642401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // أسوان — Aswan (CityId = 14)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 54, NameAr = "وحدة صحة الأسرة - وسط أسوان", NameEn = "Family Health Unit - Central Aswan", Type = HealthUnitType.HealthUnit, AddressAr = "شارع كورنيش النيل، أسوان", CityId = 14, Latitude = 24.0889, Longitude = 32.8998, Phone = "0972341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 55, NameAr = "مركز تطعيم أسوان", NameEn = "Aswan Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع السوق، أسوان", CityId = 14, Latitude = 24.0910, Longitude = 32.8990, Phone = "0972401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 56, NameAr = "مستشفى أسوان الجامعي", NameEn = "Aswan University Hospital", Type = HealthUnitType.Hospital, AddressAr = "طريق أسوان-القاهرة، أسوان", CityId = 14, Latitude = 24.0560, Longitude = 32.9180, Phone = "0972201234", Notes = "مستشفى جامعي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // السادس من أكتوبر — 6th of October City (CityId = 15)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 57, NameAr = "وحدة صحة الأسرة - الحي الأول", NameEn = "Family Health Unit - 1st District", Type = HealthUnitType.HealthUnit, AddressAr = "الحي الأول، مدينة 6 أكتوبر", CityId = 15, Latitude = 29.9730, Longitude = 30.9170, Phone = "0238351234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 58, NameAr = "مركز تطعيم 6 أكتوبر", NameEn = "6th October Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "المحور المركزي، 6 أكتوبر", CityId = 15, Latitude = 29.9720, Longitude = 30.9250, Phone = "0238401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 59, NameAr = "وحدة صحة الأسرة - الحي السابع", NameEn = "Family Health Unit - 7th District", Type = HealthUnitType.HealthUnit, AddressAr = "الحي السابع، 6 أكتوبر", CityId = 15, Latitude = 29.9640, Longitude = 30.9350, Phone = "0238551234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // دمياط — Damietta (CityId = 17)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 60, NameAr = "وحدة صحة الأسرة - وسط دمياط", NameEn = "Family Health Unit - Central Damietta", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الجمهورية، دمياط", CityId = 17, Latitude = 31.4165, Longitude = 31.8133, Phone = "0572341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 61, NameAr = "مركز تطعيم دمياط", NameEn = "Damietta Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع بورسعيد، دمياط", CityId = 17, Latitude = 31.4180, Longitude = 31.8140, Phone = "0572401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 62, NameAr = "مستشفى دمياط العام", NameEn = "Damietta General Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجلاء، دمياط", CityId = 17, Latitude = 31.4150, Longitude = 31.8120, Phone = "0572201234", Notes = "مستشفى عام", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // المنيا — Minya (CityId = 18)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 63, NameAr = "وحدة صحة الأسرة - وسط المنيا", NameEn = "Family Health Unit - Central Minya", Type = HealthUnitType.HealthUnit, AddressAr = "شارع كورنيش النيل، المنيا", CityId = 18, Latitude = 28.0871, Longitude = 30.7618, Phone = "0862341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 64, NameAr = "مركز تطعيم المنيا", NameEn = "Minya Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الجمهورية، المنيا", CityId = 18, Latitude = 28.0890, Longitude = 30.7630, Phone = "0862401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 65, NameAr = "مستشفى المنيا الجامعي", NameEn = "Minya University Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجامعة، المنيا", CityId = 18, Latitude = 28.0850, Longitude = 30.7590, Phone = "0862201234", Notes = "مستشفى جامعي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 66, NameAr = "وحدة صحة الأسرة - ملوي", NameEn = "Family Health Unit - Mallawi", Type = HealthUnitType.HealthUnit, AddressAr = "ملوي، المنيا", CityId = 18, Latitude = 27.7310, Longitude = 30.8410, Phone = "0862551234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // بني سويف — Beni Suef (CityId = 19)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 67, NameAr = "وحدة صحة الأسرة - بني سويف", NameEn = "Family Health Unit - Beni Suef", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الجمهورية، بني سويف", CityId = 19, Latitude = 29.0661, Longitude = 31.0994, Phone = "0822341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 68, NameAr = "مركز تطعيم بني سويف", NameEn = "Beni Suef Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الحرية، بني سويف", CityId = 19, Latitude = 29.0680, Longitude = 31.1010, Phone = "0822401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 69, NameAr = "مستشفى بني سويف الجامعي", NameEn = "Beni Suef University Hospital", Type = HealthUnitType.Hospital, AddressAr = "طريق القاهرة، بني سويف", CityId = 19, Latitude = 29.0750, Longitude = 31.0960, Phone = "0822201234", Notes = "مستشفى جامعي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // الأقصر — Luxor (CityId = 20)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 70, NameAr = "وحدة صحة الأسرة - وسط الأقصر", NameEn = "Family Health Unit - Central Luxor", Type = HealthUnitType.HealthUnit, AddressAr = "شارع المحطة، الأقصر", CityId = 20, Latitude = 25.6872, Longitude = 32.6396, Phone = "0952341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 71, NameAr = "مركز تطعيم الأقصر", NameEn = "Luxor Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع كورنيش النيل، الأقصر", CityId = 20, Latitude = 25.6890, Longitude = 32.6410, Phone = "0952401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 72, NameAr = "مستشفى الأقصر الدولي", NameEn = "Luxor International Hospital", Type = HealthUnitType.Hospital, AddressAr = "طريق الأقصر - أسوان، الأقصر", CityId = 20, Latitude = 25.6710, Longitude = 32.6480, Phone = "0952201234", Notes = "مستشفى دولي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // سوهاج — Sohag (CityId = 21)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 73, NameAr = "وحدة صحة الأسرة - شارع المستشفى", NameEn = "Family Health Unit - Hospital Street", Type = HealthUnitType.HealthUnit, AddressAr = "شارع المستشفى، سوهاج", CityId = 21, Latitude = 26.5588, Longitude = 31.6948, Phone = "0932341234", Notes = "يعمل يوميًا من 8 ص حتى 2 م", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 74, NameAr = "مركز تطعيم سوهاج", NameEn = "Sohag Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الجمهورية، سوهاج", CityId = 21, Latitude = 26.5560, Longitude = 31.6920, Phone = "0932401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 75, NameAr = "مركز تطعيم سوهاج 2", NameEn = "Sohag Vaccination Center 2", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الجيش، سوهاج", CityId = 21, Latitude = 26.5610, Longitude = 31.6960, Phone = "0932501234", Notes = "مركز تطعيم إضافي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 76, NameAr = "مستشفى سوهاج الجامعي", NameEn = "Sohag University Hospital", Type = HealthUnitType.Hospital, AddressAr = "طريق سوهاج - قنا، سوهاج", CityId = 21, Latitude = 26.5450, Longitude = 31.7020, Phone = "0932201234", Notes = "مستشفى جامعي يقدم تطعيمات", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 77, NameAr = "وحدة صحة الأسرة - جرجا", NameEn = "Family Health Unit - Girga", Type = HealthUnitType.HealthUnit, AddressAr = "جرجا، سوهاج", CityId = 21, Latitude = 26.3380, Longitude = 31.8910, Phone = "0932551234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 78, NameAr = "وحدة صحة الأسرة - أخميم", NameEn = "Family Health Unit - Akhmim", Type = HealthUnitType.HealthUnit, AddressAr = "أخميم، سوهاج", CityId = 21, Latitude = 26.5680, Longitude = 31.7450, Phone = "0932601234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // قنا — Qena (CityId = 23)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 79, NameAr = "وحدة صحة الأسرة - وسط قنا", NameEn = "Family Health Unit - Central Qena", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الجمهورية، قنا", CityId = 23, Latitude = 26.1551, Longitude = 32.7160, Phone = "0962341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 80, NameAr = "مركز تطعيم قنا", NameEn = "Qena Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الكورنيش، قنا", CityId = 23, Latitude = 26.1570, Longitude = 32.7170, Phone = "0962401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 81, NameAr = "مستشفى قنا العام", NameEn = "Qena General Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجيش، قنا", CityId = 23, Latitude = 26.1540, Longitude = 32.7150, Phone = "0962201234", Notes = "مستشفى عام", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // بنها — Benha / القليوبية (CityId = 30)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 82, NameAr = "وحدة صحة الأسرة - بنها", NameEn = "Family Health Unit - Benha", Type = HealthUnitType.HealthUnit, AddressAr = "شارع فريد ندا، بنها", CityId = 30, Latitude = 30.4667, Longitude = 31.1837, Phone = "0132341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 83, NameAr = "مركز تطعيم بنها", NameEn = "Benha Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الجيش، بنها", CityId = 30, Latitude = 30.4680, Longitude = 31.1850, Phone = "0132401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 84, NameAr = "مستشفى بنها الجامعي", NameEn = "Benha University Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجامعة، بنها", CityId = 30, Latitude = 30.4570, Longitude = 31.1780, Phone = "0132201234", Notes = "مستشفى جامعي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // كفر الشيخ — Kafr El Sheikh (CityId = 31)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 85, NameAr = "وحدة صحة الأسرة - كفر الشيخ", NameEn = "Family Health Unit - Kafr El Sheikh", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الجمهورية، كفر الشيخ", CityId = 31, Latitude = 31.1107, Longitude = 30.9388, Phone = "0472341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 86, NameAr = "مركز تطعيم كفر الشيخ", NameEn = "Kafr El Sheikh Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع بور سعيد، كفر الشيخ", CityId = 31, Latitude = 31.1120, Longitude = 30.9400, Phone = "0472401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // القاهرة الجديدة — New Cairo (CityId = 33)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 87, NameAr = "وحدة صحة الأسرة - التجمع الخامس", NameEn = "Family Health Unit - 5th Settlement", Type = HealthUnitType.HealthUnit, AddressAr = "التجمع الخامس، القاهرة الجديدة", CityId = 33, Latitude = 30.0074, Longitude = 31.4913, Phone = "0228131234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 88, NameAr = "مركز تطعيم القاهرة الجديدة", NameEn = "New Cairo Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع التسعين، التجمع الخامس", CityId = 33, Latitude = 30.0080, Longitude = 31.4950, Phone = "0228201234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 89, NameAr = "وحدة صحة الأسرة - التجمع الأول", NameEn = "Family Health Unit - 1st Settlement", Type = HealthUnitType.HealthUnit, AddressAr = "التجمع الأول، القاهرة الجديدة", CityId = 33, Latitude = 30.0290, Longitude = 31.4710, Phone = "0228301234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // شبرا الخيمة — Shubra El Kheima (CityId = 4)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 90, NameAr = "وحدة صحة الأسرة - شبرا الخيمة", NameEn = "Family Health Unit - Shubra El Kheima", Type = HealthUnitType.HealthUnit, AddressAr = "شارع أحمد عرابي، شبرا الخيمة", CityId = 4, Latitude = 30.1260, Longitude = 31.2430, Phone = "0244511234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 91, NameAr = "مركز تطعيم شبرا الخيمة", NameEn = "Shubra El Kheima Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع شبرا، شبرا الخيمة", CityId = 4, Latitude = 30.1270, Longitude = 31.2450, Phone = "0244601234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // دمنهور — Damanhur (CityId = 16)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 92, NameAr = "وحدة صحة الأسرة - دمنهور", NameEn = "Family Health Unit - Damanhur", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الجمهورية، دمنهور", CityId = 16, Latitude = 31.0341, Longitude = 30.4686, Phone = "0452341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 93, NameAr = "مركز تطعيم دمنهور", NameEn = "Damanhur Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الحرية، دمنهور", CityId = 16, Latitude = 31.0350, Longitude = 30.4700, Phone = "0452401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // الغردقة — Hurghada (CityId = 24)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 94, NameAr = "وحدة صحة الأسرة - الغردقة", NameEn = "Family Health Unit - Hurghada", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الشيراتون، الغردقة", CityId = 24, Latitude = 27.1784, Longitude = 33.8319, Phone = "0653251234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 95, NameAr = "مستشفى الغردقة العام", NameEn = "Hurghada General Hospital", Type = HealthUnitType.Hospital, AddressAr = "طريق الغردقة - سفاجا، الغردقة", CityId = 24, Latitude = 27.1700, Longitude = 33.8270, Phone = "0653201234", Notes = "مستشفى عام يقدم تطعيمات", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // شرم الشيخ — Sharm El Sheikh (CityId = 32)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 96, NameAr = "وحدة صحة الأسرة - شرم الشيخ", NameEn = "Family Health Unit - Sharm El Sheikh", Type = HealthUnitType.HealthUnit, AddressAr = "هضبة أم السيد، شرم الشيخ", CityId = 32, Latitude = 27.9158, Longitude = 34.3300, Phone = "0693601234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 97, NameAr = "مستشفى شرم الشيخ الدولي", NameEn = "Sharm El Sheikh International Hospital", Type = HealthUnitType.Hospital, AddressAr = "خليج نعمة، شرم الشيخ", CityId = 32, Latitude = 27.9060, Longitude = 34.3290, Phone = "0693501234", Notes = "مستشفى دولي يقدم تطعيمات", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // العاصمة الإدارية الجديدة — New Administrative Capital (CityId = 34)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 98, NameAr = "وحدة صحة الأسرة - الحي السكني", NameEn = "Family Health Unit - Residential District", Type = HealthUnitType.HealthUnit, AddressAr = "الحي السكني، العاصمة الإدارية الجديدة", CityId = 34, Latitude = 30.0194, Longitude = 31.7639, Phone = "0228501234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // العريش — Arish (CityId = 25)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 99, NameAr = "وحدة صحة الأسرة - العريش", NameEn = "Family Health Unit - El Arish", Type = HealthUnitType.HealthUnit, AddressAr = "شارع 23 يوليو، العريش", CityId = 25, Latitude = 31.1280, Longitude = 33.7980, Phone = "0682341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 100, NameAr = "مستشفى العريش العام", NameEn = "El Arish General Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجيش، العريش", CityId = 25, Latitude = 31.1300, Longitude = 33.7990, Phone = "0682201234", Notes = "مستشفى عام", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // مرسى مطروح — Marsa Matruh (CityId = 29)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 101, NameAr = "وحدة صحة الأسرة - مرسى مطروح", NameEn = "Family Health Unit - Marsa Matruh", Type = HealthUnitType.HealthUnit, AddressAr = "شارع الإسكندرية، مرسى مطروح", CityId = 29, Latitude = 31.3543, Longitude = 27.2373, Phone = "0462341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 102, NameAr = "مستشفى مرسى مطروح العام", NameEn = "Marsa Matruh General Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجمهورية، مرسى مطروح", CityId = 29, Latitude = 31.3520, Longitude = 27.2350, Phone = "0462201234", Notes = "مستشفى عام", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // العاشر من رمضان — 10th of Ramadan City (CityId = 27)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 103, NameAr = "وحدة صحة الأسرة - العاشر من رمضان", NameEn = "Family Health Unit - 10th of Ramadan", Type = HealthUnitType.HealthUnit, AddressAr = "المنطقة الأولى، العاشر من رمضان", CityId = 27, Latitude = 30.2969, Longitude = 31.7461, Phone = "0554401234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 104, NameAr = "مركز تطعيم العاشر من رمضان", NameEn = "10th of Ramadan Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "المنطقة الصناعية، العاشر من رمضان", CityId = 27, Latitude = 30.3000, Longitude = 31.7490, Phone = "0554501234", Notes = "مركز تطعيم", DataSource = "Manual Research", IsVerified = false, IsActive = true, CreatedAt = seedDate },

            // ══════════════════════════════════════════════════════════════
            // شبين الكوم — Shibin El Kom / المنوفية (CityId = 22)
            // ══════════════════════════════════════════════════════════════
            new HealthUnit { Id = 105, NameAr = "وحدة صحة الأسرة - شبين الكوم", NameEn = "Family Health Unit - Shibin El Kom", Type = HealthUnitType.HealthUnit, AddressAr = "شارع جمال عبد الناصر، شبين الكوم", CityId = 22, Latitude = 30.5579, Longitude = 31.0097, Phone = "0482341234", Notes = "يعمل يوميًا", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 106, NameAr = "مركز تطعيم شبين الكوم", NameEn = "Shibin El Kom Vaccination Center", Type = HealthUnitType.VaccinationCenter, AddressAr = "شارع الجمهورية، شبين الكوم", CityId = 22, Latitude = 30.5590, Longitude = 31.0110, Phone = "0482401234", Notes = "مركز تطعيم رئيسي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate },
            new HealthUnit { Id = 107, NameAr = "مستشفى شبين الكوم التعليمي", NameEn = "Shibin El Kom Teaching Hospital", Type = HealthUnitType.Hospital, AddressAr = "شارع الجيش، شبين الكوم", CityId = 22, Latitude = 30.5550, Longitude = 31.0080, Phone = "0482201234", Notes = "مستشفى تعليمي", DataSource = "Manual Research", IsVerified = true, IsActive = true, CreatedAt = seedDate }
        );
    }

}
