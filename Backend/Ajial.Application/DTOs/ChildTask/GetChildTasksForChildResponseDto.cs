namespace Ajial.Application.DTOs.ChildTask;

public class GetChildTasksForChildResponseDto
{
    public AssignedChildDto Child { get; set; } = null!;
    public int TotalStars { get; set; }
    public List<ChildTaskCardDto> PendingTasks { get; set; } = new();
    public List<ChildTaskCardDto> CompletedTasks { get; set; } = new();
}
