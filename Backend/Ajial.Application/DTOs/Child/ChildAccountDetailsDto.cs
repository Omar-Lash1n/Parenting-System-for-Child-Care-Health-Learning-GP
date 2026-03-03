namespace Ajial.Application.DTOs.Child;

public class ChildAccountDetailsDto
{
    public Guid ChildId { get; set; }
    public string ChildLoginId { get; set; } = string.Empty;
    public bool IsAccountActive { get; set; }
}
