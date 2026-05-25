namespace Ajial.Application.DTOs.Clinic;

public class AdminClinicListResponse
{
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public List<AdminClinicListItemDto> Items { get; set; } = new();
}

public class AdminClinicListItemDto
{
    public Guid ClinicId { get; set; }
    public string? ClinicName { get; set; }
    public string DoctorName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public DateTime? SubmittedAt { get; set; }
}
