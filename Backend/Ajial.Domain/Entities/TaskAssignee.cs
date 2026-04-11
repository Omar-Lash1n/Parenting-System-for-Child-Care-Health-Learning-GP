namespace Ajial.Domain.Entities;

public class TaskAssignee
{
    public Guid TaskId { get; set; }
    public ParentTask Task { get; set; } = null!;
    public Guid ChildId { get; set; }
    public Child Child { get; set; } = null!;
}
