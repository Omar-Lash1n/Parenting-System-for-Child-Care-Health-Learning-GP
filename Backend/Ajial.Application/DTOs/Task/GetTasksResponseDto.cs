namespace Ajial.Application.DTOs.Task;

public class GetTasksResponseDto
{
    public List<TaskCardDto> Tasks { get; set; } = new();
}
