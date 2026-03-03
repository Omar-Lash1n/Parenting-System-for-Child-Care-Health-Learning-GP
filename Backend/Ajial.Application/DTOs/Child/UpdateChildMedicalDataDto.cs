namespace Ajial.Application.DTOs.Child;

public class UpdateChildMedicalDataDto
{
    // ── Personal Profile fields ──
    public string? FullName { get; set; }
    public DateTime? BirthDate { get; set; }

    // ── Medical Profile fields ──
    public double? Height { get; set; }
    public double? Weight { get; set; }
    public double? HeadCircumference { get; set; }
    public string? BloodType { get; set; }
    public string? MedicalHistory { get; set; }
}
