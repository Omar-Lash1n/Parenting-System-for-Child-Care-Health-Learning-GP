namespace Ajial.Application.DTOs.ChildTask;

public class GetChildrenForTasksResponseDto
{
    public List<ChildForTasksDto> Children { get; set; } = new();
}
