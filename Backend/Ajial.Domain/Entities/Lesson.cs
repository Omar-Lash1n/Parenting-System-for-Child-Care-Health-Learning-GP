namespace Ajial.Domain.Entities;

public class Lesson
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CategoryId { get; set; }
    public LessonCategory Category { get; set; } = null!;
    public string TitleAr { get; set; } = string.Empty;
    public string ContentAr { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string? VideoUrl { get; set; }
    public bool IsActive { get; set; } = false;
    public Guid CreatedByAdminId { get; set; }
    public User CreatedByAdmin { get; set; } = null!;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public ICollection<LessonQuestion> Questions { get; set; } = new List<LessonQuestion>();
    public ICollection<LessonProgress> Progresses { get; set; } = new List<LessonProgress>();
}
