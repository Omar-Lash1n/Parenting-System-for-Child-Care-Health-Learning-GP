namespace Ajial.Application.Interfaces;

/// <summary>
/// متتبّع الاتصال (online/offline) لمستخدمي الـ Hub.
/// In-memory tracker of active SignalR connections per user. Singleton.
/// </summary>
public interface IPresenceTracker
{
    /// <summary>تسجيل اتصال جديد. يعيد true إذا أصبح المستخدم متصلاً الآن (أول اتصال).</summary>
    bool AddConnection(Guid userId, string connectionId);

    /// <summary>إزالة اتصال. يعيد true إذا أصبح المستخدم غير متصل (آخر اتصال).</summary>
    bool RemoveConnection(Guid userId, string connectionId);

    /// <summary>هل المستخدم متصل حالياً.</summary>
    bool IsOnline(Guid userId);
}
