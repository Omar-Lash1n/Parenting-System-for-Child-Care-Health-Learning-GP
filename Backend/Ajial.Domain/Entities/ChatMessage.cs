namespace Ajial.Domain.Entities;

/// <summary>
/// نوع رسالة المحادثة بين ولي الأمر والطبيب.
/// The kind of content a chat message carries.
/// </summary>
public enum ChatMessageType
{
    Text = 0,   // رسالة نصية
    Image = 1,  // صورة (من المعرض / الكاميرا)
    File = 2    // ملف (PDF / مستند)
}

/// <summary>
/// دور مُرسِل الرسالة في المحادثة.
/// Which side of the consultation sent the message.
/// </summary>
public enum ChatParticipantRole
{
    Parent = 0, // ولي الأمر
    Doctor = 1  // الطبيب
}

/// <summary>
/// رسالة واحدة في محادثة الاستشارة المرتبطة بحجز (Booking).
/// المحادثة تربط ولي الأمر (Booking.Parent) بالطبيب (Booking.Specialist).
/// A single message in the consultation chat thread tied to a Booking.
/// </summary>
public class ChatMessage
{
    public Guid Id { get; set; }

    // ── المحادثة (مفتاحها هو الحجز) ──
    public Guid BookingId { get; set; }
    public Booking Booking { get; set; } = null!;

    // ── المُرسِل ──
    /// <summary>معرّف المستخدم (User.Id) الذي أرسل الرسالة — ولي الأمر أو الطبيب.</summary>
    public Guid SenderUserId { get; set; }

    /// <summary>دور المُرسِل (لتلوين الفقاعة وتحديد الجهة في الواجهة).</summary>
    public ChatParticipantRole SenderRole { get; set; }

    // ── المحتوى ──
    public ChatMessageType Type { get; set; } = ChatMessageType.Text;

    /// <summary>نص الرسالة — مطلوب عندما يكون النوع Text، واختياري كتعليق على المرفق.</summary>
    public string? Content { get; set; }

    /// <summary>رابط المرفق على Azure Blob — للنوعين Image و File.</summary>
    public string? AttachmentUrl { get; set; }

    /// <summary>اسم الملف الأصلي المعروض للمستخدم — للنوع File.</summary>
    public string? AttachmentName { get; set; }

    public DateTime CreatedAt { get; set; }
}
