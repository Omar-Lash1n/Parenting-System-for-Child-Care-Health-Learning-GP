namespace Ajial.Application.DTOs.Parent;

/// <summary>
/// Response after uploading parent profile image
/// </summary>
public class UploadParentImageResponseDto
{
    /// <summary>
    /// Parent ID
    /// </summary>
    public Guid ParentId { get; set; }
    
    /// <summary>
    /// New profile image URL
    /// </summary>
    public string ProfileImageUrl { get; set; } = string.Empty;
    
    /// <summary>
    /// When the image was uploaded
    /// </summary>
    public DateTime UploadedAt { get; set; }
    
    /// <summary>
    /// Success message
    /// </summary>
    public string Message { get; set; } = string.Empty;
}