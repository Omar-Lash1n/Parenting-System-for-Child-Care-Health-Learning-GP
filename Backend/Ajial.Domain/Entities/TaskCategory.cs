namespace Ajial.Domain.Entities;

public class TaskCategory
{
    public Guid Id { get; set; }
    public Guid ParentId { get; set; }
    public Parent Parent { get; set; } = null!;
    public string Name { get; set; } = string.Empty;
    public bool IsSystem { get; set; } = false;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public ICollection<ParentTask> Tasks { get; set; } = new List<ParentTask>();
}
