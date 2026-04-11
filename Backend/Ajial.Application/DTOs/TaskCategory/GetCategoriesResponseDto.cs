namespace Ajial.Application.DTOs.TaskCategory;

public class GetCategoriesResponseDto
{
    public List<CategoryItemDto> Categories { get; set; } = new();
}

public class CategoryItemDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public bool IsSystem { get; set; }
    public int TaskCount { get; set; }
}
