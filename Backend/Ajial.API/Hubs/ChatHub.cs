using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace Ajial.API.Hubs;

/// <summary>
/// Hub محادثة الاستشارة بين ولي الأمر والطبيب (المرحلة السابعة).
/// مجموعة واحدة لكل حجز ("booking:{id}"). يبثّ الرسائل والكتابة والتواجد في الوقت الحقيقي.
///
/// أحداث يستقبلها العميل:
///   ReceiveMessage(ChatMessageDto)        — رسالة جديدة
///   Typing({ userId, isTyping })          — الطرف الآخر يكتب / توقف
///   PresenceChanged({ userId, isOnline }) — تغيّر تواجد الطرف الآخر
///   ErrorMessage(string)                  — خطأ (نافذة مغلقة / غير مصرح)
///
/// طرق يستدعيها العميل:
///   JoinConversation(bookingId)
///   LeaveConversation(bookingId)
///   SendMessage(bookingId, content)
///   Typing(bookingId, isTyping)
/// </summary>
[Authorize]
public class ChatHub : Hub
{
    private readonly IChatService _chatService;
    private readonly IPresenceTracker _presence;

    private const string JoinedBookingsKey = "joinedBookings";

    public ChatHub(IChatService chatService, IPresenceTracker presence)
    {
        _chatService = chatService;
        _presence = presence;
    }

    /// <summary>اسم مجموعة الـ Hub لحجز معيّن.</summary>
    public static string GroupFor(Guid bookingId) => $"booking:{bookingId}";

    public override Task OnConnectedAsync()
    {
        var userId = GetUserId();
        if (userId != Guid.Empty)
        {
            _presence.AddConnection(userId, Context.ConnectionId);
            Context.Items[JoinedBookingsKey] = new HashSet<Guid>();
        }
        return base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = GetUserId();
        if (userId != Guid.Empty)
        {
            var becameOffline = _presence.RemoveConnection(userId, Context.ConnectionId);

            // أبلِغ كل محادثة كان منضماً إليها بأنه أصبح غير متصل (إن لم يبقَ له اتصال آخر)
            if (becameOffline && Context.Items.TryGetValue(JoinedBookingsKey, out var raw) && raw is HashSet<Guid> bookings)
            {
                foreach (var bookingId in bookings)
                {
                    await Clients.OthersInGroup(GroupFor(bookingId))
                        .SendAsync("PresenceChanged", new { userId, isOnline = false });
                }
            }
        }
        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>الانضمام لمحادثة حجز بعد التحقق من أن المستخدم طرف فيها.</summary>
    public async Task JoinConversation(Guid bookingId)
    {
        var userId = GetUserId();
        if (userId == Guid.Empty || !await _chatService.CanAccessConversationAsync(userId, bookingId))
        {
            await Clients.Caller.SendAsync("ErrorMessage", "غير مصرح بالدخول لهذه المحادثة");
            return;
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, GroupFor(bookingId));
        if (Context.Items.TryGetValue(JoinedBookingsKey, out var raw) && raw is HashSet<Guid> bookings)
            bookings.Add(bookingId);

        // أعلِم الطرف الآخر بأنني أصبحت متصلاً في هذه المحادثة
        await Clients.OthersInGroup(GroupFor(bookingId))
            .SendAsync("PresenceChanged", new { userId, isOnline = true });
    }

    /// <summary>مغادرة محادثة حجز.</summary>
    public async Task LeaveConversation(Guid bookingId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, GroupFor(bookingId));
        if (Context.Items.TryGetValue(JoinedBookingsKey, out var raw) && raw is HashSet<Guid> bookings)
            bookings.Remove(bookingId);
    }

    /// <summary>إرسال رسالة نصية — يُخزِّنها الخدمة ثم تبثّها للمجموعة.</summary>
    public async Task SendMessage(Guid bookingId, string content)
    {
        var userId = GetUserId();
        if (userId == Guid.Empty)
        {
            await Clients.Caller.SendAsync("ErrorMessage", "غير مصرح");
            return;
        }

        var result = await _chatService.SendTextMessageAsync(userId, bookingId, content);
        if (!result.Success)
            await Clients.Caller.SendAsync("ErrorMessage", result.Message);
        // عند النجاح يتكفّل الـ notifier ببثّ ReceiveMessage لكل المجموعة (بما فيهم المُرسِل)
    }

    /// <summary>إشعار الكتابة (لا يُخزَّن).</summary>
    public async Task Typing(Guid bookingId, bool isTyping)
    {
        var userId = GetUserId();
        if (userId == Guid.Empty) return;
        await Clients.OthersInGroup(GroupFor(bookingId))
            .SendAsync("Typing", new { userId, isTyping });
    }

    private Guid GetUserId()
    {
        var value = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? Context.User?.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
            ?? Context.User?.FindFirst("sub")?.Value;
        return Guid.TryParse(value, out var id) ? id : Guid.Empty;
    }
}
