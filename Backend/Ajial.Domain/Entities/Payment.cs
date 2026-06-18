namespace Ajial.Domain.Entities;

/// <summary>
/// إيصال دفع لحجز — يرفعه ولي الأمر ويراجعه الأدمن (قبول/رفض).
/// A payment receipt for a booking — uploaded by the parent and reviewed (approve/reject) by the admin.
/// </summary>
public class Payment
{
    public Guid Id { get; set; }

    public Guid BookingId { get; set; }
    public Booking Booking { get; set; } = null!;

    public Guid ParentId { get; set; }
    public Parent Parent { get; set; } = null!;

    public PaymentMethod Method { get; set; }
    public decimal Amount { get; set; }

    /// <summary>صورة إيصال التحويل (Azure Blob URL).</summary>
    public string ReceiptImageUrl { get; set; } = string.Empty;

    public PaymentStatus Status { get; set; } = PaymentStatus.Pending;
    public string? RejectionReason { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public Guid? ReviewedByUserId { get; set; }
}
