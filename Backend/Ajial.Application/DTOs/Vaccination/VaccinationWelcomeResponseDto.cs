namespace Ajial.Application.DTOs.Vaccination;

/// <summary>
/// صفحة الترحيب - Welcome page DTO for the vaccination section
/// Returns the child's name and profile image
/// </summary>
public class VaccinationWelcomeResponseDto
{
    /// <summary>
    /// معرّف الطفل
    /// </summary>
    public Guid ChildId { get; set; }

    /// <summary>
    /// اسم الطفل الكامل
    /// </summary>
    public string FullName { get; set; } = string.Empty;

    /// <summary>
    /// رابط صورة الطفل (null إذا لم تكن موجودة)
    /// </summary>
    public string? ProfileImageUrl { get; set; }
}
