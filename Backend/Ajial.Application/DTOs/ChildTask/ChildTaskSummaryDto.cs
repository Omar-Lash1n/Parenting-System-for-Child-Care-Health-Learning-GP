namespace Ajial.Application.DTOs.ChildTask;

public class ChildTaskSummaryDto
{
    public int TotalChildTasks { get; set; }
    public int TotalPendingTasks { get; set; }
    public int TotalCompletedTasks { get; set; }
    public int CompletedToday { get; set; }
    public List<ChildSummaryItemDto> PerChild { get; set; } = new();
}

public class ChildSummaryItemDto
{
    public Guid ChildId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public int TotalStars { get; set; }
    public int PendingTasksCount { get; set; }
    public int CompletedTasksCount { get; set; }
}
