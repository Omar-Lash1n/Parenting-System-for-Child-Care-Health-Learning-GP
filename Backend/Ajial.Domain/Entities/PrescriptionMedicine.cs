namespace Ajial.Domain.Entities;

/// <summary>
/// دواء واحد ضمن الروشتة الطبية لحجز استشارة — يضيفه الطبيب بعد إنهاء الجلسة.
/// A single medicine line within a booking's prescription (الروشتة الطبية), added by the doctor.
/// </summary>
public class PrescriptionMedicine
{
    public Guid Id { get; set; }

    public Guid BookingId { get; set; }
    public Booking Booking { get; set; } = null!;

    /// <summary>اسم الدواء (مثل: كونجستال).</summary>
    public string MedicineName { get; set; } = string.Empty;

    /// <summary>الكمية / الجرعة (مثل: نصف قرص يومياً).</summary>
    public string Quantity { get; set; } = string.Empty;

    /// <summary>الموعد / توقيت تناول الدواء (مثل: قبل الغذاء).</summary>
    public string Timing { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
