namespace Ajial.Domain.Entities;

public class RankingEntry
{
    public Guid Id { get; set; }
    public Guid RankingCycleId { get; set; }
    public RankingCycle RankingCycle { get; set; } = null!;
    public Guid ParentId { get; set; }
    public Parent Parent { get; set; } = null!;
    public int Stars { get; set; }
    public int Rank { get; set; }
    public BadgeType? Badge { get; set; }
}
