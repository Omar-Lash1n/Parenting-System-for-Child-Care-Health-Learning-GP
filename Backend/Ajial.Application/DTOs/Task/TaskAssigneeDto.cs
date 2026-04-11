namespace Ajial.Application.DTOs.Task;

public class TaskAssigneeDto
{
    /// <summary>
    /// "parent" or "child"
    /// </summary>
    public string Type { get; set; } = string.Empty;
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
}
