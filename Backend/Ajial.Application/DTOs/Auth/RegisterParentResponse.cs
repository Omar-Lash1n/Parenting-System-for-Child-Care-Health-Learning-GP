namespace Ajial.Application.DTOs.Auth;

public class RegisterParentResponse
{
    public Guid UserId { get; set; }
    public Guid ParentId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}