using System.Collections.Concurrent;
using Ajial.Application.Interfaces;

namespace Ajial.API.Realtime;

/// <summary>
/// متتبّع الاتصال في الذاكرة — يربط كل مستخدم بمجموعة اتصالاته النشطة على الـ Hub.
/// Singleton. Thread-safe via a lock around the per-user connection set.
/// </summary>
public class PresenceTracker : IPresenceTracker
{
    private readonly ConcurrentDictionary<Guid, HashSet<string>> _connections = new();

    public bool AddConnection(Guid userId, string connectionId)
    {
        bool becameOnline;
        var set = _connections.GetOrAdd(userId, _ => new HashSet<string>());
        lock (set)
        {
            becameOnline = set.Count == 0;
            set.Add(connectionId);
        }
        return becameOnline;
    }

    public bool RemoveConnection(Guid userId, string connectionId)
    {
        if (!_connections.TryGetValue(userId, out var set)) return false;

        bool becameOffline;
        lock (set)
        {
            set.Remove(connectionId);
            becameOffline = set.Count == 0;
        }

        if (becameOffline)
            _connections.TryRemove(userId, out _);

        return becameOffline;
    }

    public bool IsOnline(Guid userId) =>
        _connections.TryGetValue(userId, out var set) && set.Count > 0;
}
