namespace Ajial.Application.DTOs.Home;

public class CurrentVaccinationCardDto
{
    public Guid ChildId { get; set; }
    public string ChildName { get; set; } = string.Empty;
    public string? ChildImageUrl { get; set; }
    public int VaccinationMilestoneId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime DueDate { get; set; }
    public string AgeLabel { get; set; } = string.Empty;
    public string Status { get; set; } = "current";
    public bool IsReminderEnabled { get; set; }
    public DateTime? ReminderDateTime { get; set; }
}
