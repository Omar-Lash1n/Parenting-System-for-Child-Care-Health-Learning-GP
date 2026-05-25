namespace Ajial.Domain.Entities;

public class RemoteConsultation
{
    public Guid Id { get; set; }
    public Guid SpecialistId { get; set; }
    public Specialist Specialist { get; set; } = null!;

    public decimal? SessionPrice { get; set; }
    public int? SessionDurationMinutes { get; set; }
    public int? WaitingPeriodMinutes { get; set; }
    public string? WorkingHoursJson { get; set; }

    public RemoteConsultationStatus Status { get; set; } = RemoteConsultationStatus.Draft;
    public string? RejectionReason { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? SubmittedAt { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public Guid? ReviewedByUserId { get; set; }
}
