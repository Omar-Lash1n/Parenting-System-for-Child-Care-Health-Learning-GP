using Microsoft.AspNetCore.Http;

namespace Ajial.Application.DTOs.Chat;

/// <summary>رسالة محادثة واحدة كما تُعرض في الواجهة.</summary>
public class ChatMessageDto
{
    public Guid Id { get; set; }
    public Guid BookingId { get; set; }

    public Guid SenderUserId { get; set; }
    /// <summary>"parent" أو "doctor".</summary>
    public string SenderRole { get; set; } = string.Empty;

    /// <summary>هل الرسالة من المستخدم الحالي (لمحاذاة الفقاعة يمين/يسار).</summary>
    public bool IsMine { get; set; }

    /// <summary>"text" | "image" | "file".</summary>
    public string Type { get; set; } = "text";

    public string? Content { get; set; }
    public string? AttachmentUrl { get; set; }
    public string? AttachmentName { get; set; }

    /// <summary>وقت الإنشاء (UTC، ISO-8601). تُحوَّل للوقت المحلي في الواجهة.</summary>
    public DateTime CreatedAt { get; set; }
}

/// <summary>الطرف الآخر في المحادثة (يُعرض في ترويسة الشاشة).</summary>
public class ChatParticipantDto
{
    public Guid UserId { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    /// <summary>تخصص الطبيب — يكون null عندما يكون الطرف الآخر ولي الأمر.</summary>
    public string? Specialty { get; set; }
    public bool IsOnline { get; set; }
}

/// <summary>
/// معلومات المحادثة + الرسائل (رد فتح الشاشة).
/// </summary>
public class ConversationResponse
{
    public Guid BookingId { get; set; }

    /// <summary>الطرف الآخر (الطبيب بالنسبة لولي الأمر، والعكس).</summary>
    public ChatParticipantDto Participant { get; set; } = new();

    /// <summary>هل يُسمح بإرسال رسائل الآن (المحادثة مفتوحة).</summary>
    public bool CanSendMessages { get; set; }

    /// <summary>حالة النافذة: "open" | "closed" | "notAllowed".</summary>
    public string WindowState { get; set; } = "closed";

    /// <summary>رسالة توضيحية تُعرض عند إغلاق المحادثة.</summary>
    public string? WindowNotice { get; set; }

    /// <summary>وقت إغلاق المحادثة (3 أيام بعد الجلسة) — UTC، أو null إن لم يُحدَّد بعد.</summary>
    public DateTime? WindowClosesAt { get; set; }

    /// <summary>الرسائل من الأقدم إلى الأحدث.</summary>
    public List<ChatMessageDto> Messages { get; set; } = new();
}

/// <summary>عنصر في قائمة محادثاتي (صندوق الوارد).</summary>
public class ConversationListItemDto
{
    public Guid BookingId { get; set; }
    public ChatParticipantDto Participant { get; set; } = new();
    public string? LastMessagePreview { get; set; }
    public DateTime? LastMessageAt { get; set; }
    public bool CanSendMessages { get; set; }
}

/// <summary>طلب إرسال رسالة نصية.</summary>
public class SendTextMessageRequest
{
    public string Content { get; set; } = string.Empty;
}

/// <summary>طلب إرسال مرفق (صورة أو ملف) — multipart/form-data.</summary>
public class SendAttachmentRequest
{
    public IFormFile File { get; set; } = null!;
    /// <summary>تعليق نصي اختياري يُرفق مع المرفق.</summary>
    public string? Caption { get; set; }
}
