namespace Ajial.Application.DTOs.RemoteConsultation;

public class AdminRemoteConsultationListResponse
{
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public List<AdminRemoteConsultationListItemDto> Items { get; set; } = new();
}

public class AdminRemoteConsultationListItemDto
{
    public Guid ConsultationId { get; set; }
    public string DoctorName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public DateTime? SubmittedAt { get; set; }
}
