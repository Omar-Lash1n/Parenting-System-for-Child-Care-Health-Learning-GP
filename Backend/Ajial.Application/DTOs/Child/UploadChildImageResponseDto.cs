namespace Ajial.Application.DTOs.Child;

public class UploadChildImageResponseDto
{
    public Guid ChildId { get; set; }
    public string ProfileImageUrl { get; set; } = string.Empty;
    public DateTime UploadedAt { get; set; }
    public string Message { get; set; } = string.Empty;
}
