namespace Ajial.Application.DTOs.Child;

public class AddChildResponseDto
{
    public Guid ChildId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public DateTime BirthDate { get; set; }
    public int Age { get; set; }
    public string Gender { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public string? ChildLoginId { get; set; }
    public bool RequiresPassword { get; set; }
    public string Message { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}