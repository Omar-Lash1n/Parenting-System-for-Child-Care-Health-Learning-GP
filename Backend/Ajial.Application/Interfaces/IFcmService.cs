namespace Ajial.Application.Interfaces;

/// <summary>
/// Abstraction over Firebase Cloud Messaging.
/// Only used for vaccination appointment push notifications.
/// </summary>
public interface IFcmService
{
    /// <summary>
    /// Sends a push notification to a specific device via FCM.
    /// </summary>
    /// <param name="deviceToken">The recipient's FCM registration token.</param>
    /// <param name="title">Notification title shown on the phone screen.</param>
    /// <param name="body">Notification body / description text.</param>
    /// <param name="data">Optional key-value data payload for Flutter to handle silently.</param>
    Task<bool> SendPushAsync(string deviceToken, string title, string body, Dictionary<string, string>? data = null);
}
