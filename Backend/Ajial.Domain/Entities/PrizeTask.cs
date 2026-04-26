namespace Ajial.Domain.Entities;

public class PrizeTask
{
    public Guid PrizeId { get; set; }
    public Prize Prize { get; set; } = null!;

    public Guid TaskId { get; set; }
    public ChildTask Task { get; set; } = null!;
}
