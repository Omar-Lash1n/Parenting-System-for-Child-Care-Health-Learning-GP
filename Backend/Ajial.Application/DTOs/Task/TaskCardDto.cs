namespace Ajial.Application.DTOs.Task;

public class TaskCardDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Color { get; set; }
    public DateTime? DueDate { get; set; }
    public bool IsCompleted { get; set; }
    public DateTime? CompletedAt { get; set; }
    public TaskCategoryDto Category { get; set; } = null!;
    public List<TaskAssigneeDto> Assignees { get; set; } = new();
}
