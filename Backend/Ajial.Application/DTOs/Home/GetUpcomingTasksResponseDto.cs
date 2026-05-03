using Ajial.Application.DTOs.Task;

namespace Ajial.Application.DTOs.Home;

public class GetUpcomingTasksResponseDto
{
    public List<TaskCardDto> Tasks { get; set; } = new();
}
