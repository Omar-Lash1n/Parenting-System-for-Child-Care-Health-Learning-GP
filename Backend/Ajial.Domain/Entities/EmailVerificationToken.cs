namespace Ajial.Domain.Entities;

/// <summary>
/// Email verification token entity
/// رمز التحقق من البريد الإلكتروني
/// </summary>
public class EmailVerificationToken
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;

    public string Token { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime ExpiresAt { get; set; }
    public bool IsUsed { get; set; }
    public DateTime? UsedAt { get; set; }
}
