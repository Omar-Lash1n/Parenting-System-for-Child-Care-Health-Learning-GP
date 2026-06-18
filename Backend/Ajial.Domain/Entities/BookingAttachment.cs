namespace Ajial.Domain.Entities;

/// <summary>
/// صورة مرفقة بالحجز (تحاليل أو أشعة) رفعها ولي الأمر.
/// An image (lab result / X-ray) the parent attached to a booking.
/// </summary>
public class BookingAttachment
{
    public Guid Id { get; set; }
    public Guid BookingId { get; set; }
    public Booking Booking { get; set; } = null!;
    public string ImageUrl { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
