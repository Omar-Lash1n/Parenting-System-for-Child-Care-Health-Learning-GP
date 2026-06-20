using Ajial.Application.DTOs.Chat;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Helpers;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;
using Microsoft.AspNetCore.Http;

namespace Ajial.Application.Service;

/// <summary>
/// محادثة الاستشارة بين ولي الأمر والطبيب (المرحلة السابعة).
/// تُخزِّن الرسائل في قاعدة البيانات وتبثّها فوراً عبر <see cref="IChatRealtimeNotifier"/> (SignalR).
/// </summary>
public class ChatService : IChatService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IImageService _imageService;
    private readonly IChatRealtimeNotifier _notifier;
    private readonly IPresenceTracker _presence;

    /// <summary>مدة بقاء المحادثة مفتوحة بعد الجلسة.</summary>
    private static readonly TimeSpan ChatWindowAfterSession = TimeSpan.FromDays(3);

    public ChatService(
        IUnitOfWork unitOfWork,
        IImageService imageService,
        IChatRealtimeNotifier notifier,
        IPresenceTracker presence)
    {
        _unitOfWork = unitOfWork;
        _imageService = imageService;
        _notifier = notifier;
        _presence = presence;
    }

    // ── فتح محادثة ─────────────────────────────────────────────────────────────

    public async Task<ApiResponse<ConversationResponse>> GetConversationAsync(Guid userId, Guid bookingId)
    {
        var booking = await _unitOfWork.Bookings.GetFirstOrDefaultAsync(
            b => b.Id == bookingId, "Parent.User,Specialist.User");

        if (booking == null)
            return ApiResponse<ConversationResponse>.FailureResponse("لم يتم العثور على الحجز");

        if (!TryResolveRole(booking, userId, out var role))
            return ApiResponse<ConversationResponse>.FailureResponse("غير مصرح");

        var window = EvaluateWindow(booking);

        var messages = (await _unitOfWork.ChatMessages.FindAsync(m => m.BookingId == bookingId))
            .OrderBy(m => m.CreatedAt)
            .Select(m => MapMessage(m, userId))
            .ToList();

        var response = new ConversationResponse
        {
            BookingId = bookingId,
            Participant = BuildOtherParty(booking, role),
            CanSendMessages = window.CanSend,
            WindowState = window.State,
            WindowNotice = window.Notice,
            WindowClosesAt = window.ClosesAt,
            Messages = messages
        };

        return ApiResponse<ConversationResponse>.SuccessResponse(response);
    }

    // ── صندوق الوارد ───────────────────────────────────────────────────────────

    public async Task<ApiResponse<List<ConversationListItemDto>>> GetMyConversationsAsync(Guid userId)
    {
        var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == userId);
        var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.UserId == userId);

        if (parent == null && specialist == null)
            return ApiResponse<List<ConversationListItemDto>>.SuccessResponse(new List<ConversationListItemDto>());

        var bookings = (await _unitOfWork.Bookings.FindAsync(b =>
                (parent != null && b.ParentId == parent.Id) ||
                (specialist != null && b.SpecialistId == specialist.Id)))
            .Where(b => b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.Completed)
            .ToList();

        var items = new List<ConversationListItemDto>();
        foreach (var b in bookings)
        {
            // تحميل الحجز مع أطراف المحادثة لبناء بطاقة الطرف الآخر
            var full = await _unitOfWork.Bookings.GetFirstOrDefaultAsync(
                x => x.Id == b.Id, "Parent.User,Specialist.User");
            if (full == null || !TryResolveRole(full, userId, out var role)) continue;

            var lastMessage = (await _unitOfWork.ChatMessages.FindAsync(m => m.BookingId == b.Id))
                .OrderByDescending(m => m.CreatedAt)
                .FirstOrDefault();

            items.Add(new ConversationListItemDto
            {
                BookingId = b.Id,
                Participant = BuildOtherParty(full, role),
                LastMessagePreview = PreviewOf(lastMessage),
                LastMessageAt = lastMessage?.CreatedAt,
                CanSendMessages = EvaluateWindow(full).CanSend
            });
        }

        return ApiResponse<List<ConversationListItemDto>>.SuccessResponse(
            items.OrderByDescending(i => i.LastMessageAt ?? DateTime.MinValue).ToList());
    }

    // ── إرسال ──────────────────────────────────────────────────────────────────

    public async Task<ApiResponse<ChatMessageDto>> SendTextMessageAsync(Guid userId, Guid bookingId, string content)
    {
        if (string.IsNullOrWhiteSpace(content))
            return ApiResponse<ChatMessageDto>.FailureResponse("لا يمكن إرسال رسالة فارغة");

        return await PersistAndBroadcastAsync(userId, bookingId, ChatMessageType.Text, content.Trim(), null, null);
    }

    public async Task<ApiResponse<ChatMessageDto>> SendAttachmentAsync(Guid userId, Guid bookingId, IFormFile file, string? caption)
    {
        if (file == null || file.Length == 0)
            return ApiResponse<ChatMessageDto>.FailureResponse("الملف فارغ");

        // التحقق من الصلاحية والنافذة قبل رفع الملف لتفادي رفع بلا داعٍ
        var booking = await _unitOfWork.Bookings.GetFirstOrDefaultAsync(
            b => b.Id == bookingId, "Parent.User,Specialist.User");
        if (booking == null)
            return ApiResponse<ChatMessageDto>.FailureResponse("لم يتم العثور على الحجز");
        if (!TryResolveRole(booking, userId, out var role))
            return ApiResponse<ChatMessageDto>.FailureResponse("غير مصرح");
        var window = EvaluateWindow(booking);
        if (!window.CanSend)
            return ApiResponse<ChatMessageDto>.FailureResponse(window.Notice ?? "المحادثة مغلقة حالياً");

        var url = await _imageService.UploadChatAttachmentAsync(file, bookingId);
        var isImage = (file.ContentType ?? string.Empty).StartsWith("image/", StringComparison.OrdinalIgnoreCase);
        var type = isImage ? ChatMessageType.Image : ChatMessageType.File;
        var attachmentName = isImage ? null : file.FileName;

        return await PersistAndBroadcastAsync(userId, bookingId, type,
            string.IsNullOrWhiteSpace(caption) ? null : caption!.Trim(), url, attachmentName,
            preloadedBooking: booking, preloadedRole: role);
    }

    public async Task<bool> CanAccessConversationAsync(Guid userId, Guid bookingId)
    {
        var booking = await _unitOfWork.Bookings.GetFirstOrDefaultAsync(
            b => b.Id == bookingId, "Parent,Specialist");
        return booking != null && TryResolveRole(booking, userId, out _);
    }

    // ── الجوهر: تخزين ثم بثّ ─────────────────────────────────────────────────────

    private async Task<ApiResponse<ChatMessageDto>> PersistAndBroadcastAsync(
        Guid userId, Guid bookingId, ChatMessageType type,
        string? content, string? attachmentUrl, string? attachmentName,
        Booking? preloadedBooking = null, ChatParticipantRole? preloadedRole = null)
    {
        var booking = preloadedBooking ?? await _unitOfWork.Bookings.GetFirstOrDefaultAsync(
            b => b.Id == bookingId, "Parent.User,Specialist.User");
        if (booking == null)
            return ApiResponse<ChatMessageDto>.FailureResponse("لم يتم العثور على الحجز");

        ChatParticipantRole role;
        if (preloadedRole.HasValue) role = preloadedRole.Value;
        else if (!TryResolveRole(booking, userId, out role))
            return ApiResponse<ChatMessageDto>.FailureResponse("غير مصرح");

        var window = EvaluateWindow(booking);
        if (!window.CanSend)
            return ApiResponse<ChatMessageDto>.FailureResponse(window.Notice ?? "المحادثة مغلقة حالياً");

        var entity = new ChatMessage
        {
            Id = Guid.NewGuid(),
            BookingId = bookingId,
            SenderUserId = userId,
            SenderRole = role,
            Type = type,
            Content = content,
            AttachmentUrl = attachmentUrl,
            AttachmentName = attachmentName,
            CreatedAt = DateTime.UtcNow
        };

        await _unitOfWork.ChatMessages.AddAsync(entity);
        await _unitOfWork.SaveChangesAsync();

        // البثّ بـ IsMine = false؛ كل عميل يقارن SenderUserId بمعرّفه لتحديد جهة الفقاعة
        var broadcastDto = MapMessage(entity, Guid.Empty);
        await _notifier.BroadcastMessageAsync(bookingId, broadcastDto);

        // الرد على المُرسِل بنسخته (IsMine = true)
        return ApiResponse<ChatMessageDto>.SuccessResponse(MapMessage(entity, userId), "تم الإرسال");
    }

    // ── مساعدات ────────────────────────────────────────────────────────────────

    private static bool TryResolveRole(Booking booking, Guid userId, out ChatParticipantRole role)
    {
        if (booking.Parent != null && booking.Parent.UserId == userId)
        {
            role = ChatParticipantRole.Parent;
            return true;
        }
        if (booking.Specialist != null && booking.Specialist.UserId == userId)
        {
            role = ChatParticipantRole.Doctor;
            return true;
        }
        role = default;
        return false;
    }

    /// <summary>يبني بطاقة الطرف الآخر من منظور صاحب الدور <paramref name="myRole"/>.</summary>
    private ChatParticipantDto BuildOtherParty(Booking booking, ChatParticipantRole myRole)
    {
        if (myRole == ChatParticipantRole.Parent)
        {
            var s = booking.Specialist;
            return new ChatParticipantDto
            {
                UserId = s.UserId,
                FullName = s.User?.FullName ?? "الطبيب",
                AvatarUrl = string.IsNullOrWhiteSpace(s.PersonalPhotoUrl) ? null : s.PersonalPhotoUrl,
                Specialty = s.Specialization,
                IsOnline = _presence.IsOnline(s.UserId)
            };
        }

        var p = booking.Parent;
        return new ChatParticipantDto
        {
            UserId = p.UserId,
            FullName = p.User?.FullName ?? "ولي الأمر",
            AvatarUrl = string.IsNullOrWhiteSpace(p.ProfileImageUrl) ? null : p.ProfileImageUrl,
            Specialty = null,
            IsOnline = _presence.IsOnline(p.UserId)
        };
    }

    private ChatMessageDto MapMessage(ChatMessage m, Guid currentUserId) => new()
    {
        Id = m.Id,
        BookingId = m.BookingId,
        SenderUserId = m.SenderUserId,
        SenderRole = m.SenderRole == ChatParticipantRole.Parent ? "parent" : "doctor",
        IsMine = m.SenderUserId == currentUserId,
        Type = m.Type switch
        {
            ChatMessageType.Image => "image",
            ChatMessageType.File => "file",
            _ => "text"
        },
        Content = m.Content,
        AttachmentUrl = m.AttachmentUrl,
        AttachmentName = m.AttachmentName,
        CreatedAt = m.CreatedAt
    };

    private static string? PreviewOf(ChatMessage? m)
    {
        if (m == null) return null;
        return m.Type switch
        {
            ChatMessageType.Image => "📷 صورة",
            ChatMessageType.File => "📎 ملف",
            _ => m.Content
        };
    }

    /// <summary>حالة نافذة المحادثة: متاحة من تأكيد الحجز وتغلق بعد ٣ أيام من الجلسة.</summary>
    private (bool CanSend, string State, string? Notice, DateTime? ClosesAt) EvaluateWindow(Booking booking)
    {
        if (booking.Status != BookingStatus.Confirmed && booking.Status != BookingStatus.Completed)
            return (false, "notAllowed", "لم يتم تأكيد الحجز بعد", null);

        // نهاية الجلسة (بتوقيت مصر) ثم نضيف مدة النافذة
        var sessionEnd = booking.AppointmentDate.Date +
            (booking.EndTime ?? booking.StartTime ?? new TimeSpan(23, 59, 0));
        var closesAt = sessionEnd + ChatWindowAfterSession;

        var now = WorkingHoursHelper.EgyptNow();
        if (now <= closesAt)
            return (true, "open", null, closesAt);

        return (false, "closed", "انتهت فترة التحدث مع الطبيب (انتهت بعد ٣ أيام من الجلسة)", closesAt);
    }
}
