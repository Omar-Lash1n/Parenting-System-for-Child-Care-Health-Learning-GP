using Ajial.API.Hubs;
using Ajial.Application.DTOs.Chat;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.SignalR;

namespace Ajial.API.Realtime;

/// <summary>
/// تنفيذ بثّ المحادثة فوق SignalR — يستخدمه <c>ChatService</c> (طبقة التطبيق) دون معرفة الـ Hub.
/// </summary>
public class SignalRChatNotifier : IChatRealtimeNotifier
{
    private readonly IHubContext<ChatHub> _hub;

    public SignalRChatNotifier(IHubContext<ChatHub> hub) => _hub = hub;

    public Task BroadcastMessageAsync(Guid bookingId, ChatMessageDto message) =>
        _hub.Clients.Group(ChatHub.GroupFor(bookingId)).SendAsync("ReceiveMessage", message);
}
