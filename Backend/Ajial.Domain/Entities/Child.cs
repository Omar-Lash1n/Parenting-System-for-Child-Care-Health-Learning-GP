namespace Ajial.Domain.Entities;

public class Child
{
    public Guid Id { get; set; }
    public Guid ParentId { get; set; }
    public Parent Parent { get; set; } = null!;

    public string FullName { get; set; } = string.Empty;
    public DateTime BirthDate { get; set; }
    public int Age { get; set; }
    public string Gender { get; set; } = string.Empty;
    public string? ProfileImageUrl { get; set; }
    public string? ChildLoginId { get; set; }
    public string? PasswordHash { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public bool IsActive { get; set; }

    /// <summary>
    /// Last time the child interacted with the app (for online status tracking).
    /// Child is considered "active" if this is within the last 5 minutes.
    /// آخر وقت تفاعل فيه الطفل مع التطبيق
    /// </summary>
    public DateTime? LastActivityAt { get; set; }
}