namespace Ajial.Application.DTOs.SpecialistApplication;

public class AdminApplicationListResponse
{
    public List<AdminApplicationListItemDto> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}

public class AdminApplicationListItemDto
{
    public Guid ApplicationId { get; set; }
    public string SpecialistName { get; set; } = string.Empty;
    public string SpecialtyName { get; set; } = string.Empty;
    public DateTime? SubmittedAt { get; set; }
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public string? PersonalPhotoUrl { get; set; }
}
