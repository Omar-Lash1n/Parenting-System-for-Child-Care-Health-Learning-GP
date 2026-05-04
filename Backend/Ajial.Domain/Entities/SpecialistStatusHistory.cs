namespace Ajial.Domain.Entities;

public class SpecialistStatusHistory
{
    public Guid Id { get; set; }
    public Guid SpecialistId { get; set; }
    public Specialist Specialist { get; set; } = null!;
    public SpecialistStatus FromStatus { get; set; }
    public SpecialistStatus ToStatus { get; set; }
    public string? Reason { get; set; }
    public Guid ChangedByUserId { get; set; }
    public DateTime ChangedAt { get; set; }
}
