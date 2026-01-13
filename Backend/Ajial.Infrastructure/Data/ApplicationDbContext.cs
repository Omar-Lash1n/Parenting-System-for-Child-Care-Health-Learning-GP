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

        // Seed Cities
        SeedCities(modelBuilder);
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

}