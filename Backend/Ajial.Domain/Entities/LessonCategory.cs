namespace Ajial.Domain.Entities;

public class LessonCategory
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string NameAr { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public int OrderIndex { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Lesson> Lessons { get; set; } = new List<Lesson>();
}
