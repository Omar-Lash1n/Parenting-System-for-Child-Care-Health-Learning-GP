using Ajial.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Ajial.Infrastructure.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Users { get; set; }
    public DbSet<Parent> Parents { get; set; }
    public DbSet<City> Cities { get; set; }
    public DbSet<PasswordResetToken> PasswordResetTokens { get; set; }  // ✅ NEW
    public DbSet<EmailVerificationToken> EmailVerificationTokens { get; set; }
    public DbSet<Child> Children { get; set; }
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
            new City { Id = 5, Name = "Port Said", NameAr = "بورسعيد", IsActive = true }
        );
    }

}