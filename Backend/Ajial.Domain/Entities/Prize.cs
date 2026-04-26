namespace Ajial.Domain.Entities;

public class Prize
{
    public Guid Id { get; set; }
    public Guid ParentId { get; set; }
    public Parent Parent { get; set; } = null!;

    public Guid ChildId { get; set; }
    public Child Child { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public int RequiredStars { get; set; }
    public PrizeStatus Status { get; set; } = PrizeStatus.Active;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? DeliveredAt { get; set; }

    public ICollection<PrizeTask> RequiredTasks { get; set; } = new List<PrizeTask>();
}
