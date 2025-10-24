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