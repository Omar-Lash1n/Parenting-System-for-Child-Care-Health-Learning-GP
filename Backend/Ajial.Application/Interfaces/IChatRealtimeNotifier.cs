using Ajial.Application.DTOs.Chat;

namespace Ajial.Application.Interfaces;

/// <summary>
/// تجريد لبثّ أحداث المحادثة في الوقت الحقيقي.
/// Implemented in the API layer over SignalR (<c>IHubContext&lt;ChatHub&gt;</c>) so the
/// Application layer can push messages without referencing SignalR directly.
/// </summary>
public interface IChatRealtimeNotifier
{
    /// <summary>بثّ رسالة جديدة لكل المتصلين بمحادثة الحجز.</summary>
    Task BroadcastMessageAsync(Guid bookingId, ChatMessageDto message);
}
