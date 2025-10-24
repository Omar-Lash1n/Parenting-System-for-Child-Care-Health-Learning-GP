namespace Ajial.Domain.Entities;

public class City
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string NameAr { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
}