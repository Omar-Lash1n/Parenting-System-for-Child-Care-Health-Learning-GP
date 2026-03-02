namespace Ajial.Domain.Entities;

/// <summary>
/// سجل تطعيمات الطفل - Per-child vaccination record
/// Links a child to a vaccination milestone with IsTaken flag
/// </summary>
public class ChildVaccination
{
    public Guid Id { get; set; }

    /// <summary>
    /// معرّف الطفل
    /// </summary>
    public Guid ChildId { get; set; }
    public Child Child { get; set; } = null!;

    /// <summary>
    /// معرّف التطعيم
    /// </summary>
    public int VaccinationMilestoneId { get; set; }
    public VaccinationMilestone VaccinationMilestone { get; set; } = null!;

    /// <summary>
    /// هل تم أخذ التطعيم؟
    /// </summary>
    public bool IsTaken { get; set; }

    /// <summary>
    /// تاريخ التسجيل
    /// </summary>
    public DateTime RecordedAt { get; set; }

    /// <summary>
    /// تاريخ آخر تحديث
    /// </summary>
    public DateTime UpdatedAt { get; set; }
}
