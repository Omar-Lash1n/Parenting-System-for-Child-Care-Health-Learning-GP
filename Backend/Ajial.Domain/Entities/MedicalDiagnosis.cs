namespace Ajial.Domain.Entities;

/// <summary>
/// التشخيص الطبي للمريض في حجز استشارة — يكتبه الطبيب بعد إنهاء الجلسة (تشخيص واحد لكل حجز).
/// The doctor's medical diagnosis (التشخيص الطبي) for a booking — one diagnosis per booking.
/// </summary>
public class MedicalDiagnosis
{
    public Guid Id { get; set; }

    public Guid BookingId { get; set; }
    public Booking Booking { get; set; } = null!;

    /// <summary>وصف التشخيص الطبي للمريض (نص حر).</summary>
    public string Description { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
