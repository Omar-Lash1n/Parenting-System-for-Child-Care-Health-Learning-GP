namespace Ajial.Domain.Entities;

public class Parent
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public DateTime DateOfBirth { get; set; }
    public int CityId { get; set; }
    public City City { get; set; } = null!;
    public ParentGender Gender { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    
}