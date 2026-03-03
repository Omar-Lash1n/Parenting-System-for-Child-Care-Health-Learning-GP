namespace Ajial.Application.DTOs.Child;

public class UpdateChildMedicalDataResponseDto
{
    public Guid ChildId { get; set; }
    public List<string> FieldsUpdated { get; set; } = new();
    public int ProfileCompletionPercentage { get; set; }
}
