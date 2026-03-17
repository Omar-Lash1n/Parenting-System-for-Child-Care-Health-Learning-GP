using Ajial.Application.Interfaces;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Ajial.Infrastructure.Services;

/// <summary>
/// Sends push notifications to mobile devices via Firebase Cloud Messaging (FCM).
/// Uses the service account JSON for secure server-to-server authentication.
/// </summary>
public class FcmService : IFcmService
{
    private readonly ILogger<FcmService> _logger;

    public FcmService(ILogger<FcmService> logger, IConfiguration configuration, IWebHostEnvironment env)
    {
        _logger = logger;

        // Initialize Firebase App only once (singleton-safe check)
        if (FirebaseApp.DefaultInstance == null)
        {
            var keyPath = configuration["Firebase:ServiceAccountKeyPath"];
            
            // FIX: Convert relative path to absolute physical path on Azure server
            if (!string.IsNullOrEmpty(keyPath) && !Path.IsPathRooted(keyPath))
            {
                keyPath = Path.Combine(env.ContentRootPath, keyPath);
            }

            if (string.IsNullOrEmpty(keyPath) || !File.Exists(keyPath))
            {
                _logger.LogError("Firebase service account key not found at path: {Path}", keyPath);
                throw new InvalidOperationException(
                    $"Firebase service account key file not found at: '{keyPath}'. " +
                    "Check Firebase:ServiceAccountKeyPath in appsettings.json.");
            }

            FirebaseApp.Create(new AppOptions
            {
                Credential = GoogleCredential.FromFile(keyPath)
            });

            _logger.LogInformation("✅ Firebase Admin SDK initialized successfully.");
        }
    }

    /// <inheritdoc/>
    public async Task<bool> SendPushAsync(
        string deviceToken,
        string title,
        string body,
        Dictionary<string, string>? data = null)
    {
        try
        {
            var message = new Message
            {
                Token = deviceToken,
                Notification = new Notification
                {
                    Title = title,
                    Body = body
                },
                Data = data ?? new Dictionary<string, string>(),
                Android = new AndroidConfig
                {
                    Priority = Priority.High,
                    Notification = new AndroidNotification
                    {
                        Sound = "default",
                        ClickAction = "FLUTTER_NOTIFICATION_CLICK"
                    }
                },
                Apns = new ApnsConfig
                {
                    Aps = new Aps
                    {
                        Sound = "default",
                        Badge = 1
                    }
                }
            };

            var response = await FirebaseMessaging.DefaultInstance.SendAsync(message);

            _logger.LogInformation("✅ FCM push sent. MessageId: {MessageId}", response);
            return true;
        }
        catch (FirebaseMessagingException ex) when (
            ex.MessagingErrorCode == MessagingErrorCode.Unregistered ||
            ex.MessagingErrorCode == MessagingErrorCode.InvalidArgument)
        {
            // Token is stale/invalid — Flutter app needs to re-register
            _logger.LogWarning("FCM token is invalid or unregistered. ErrorCode: {Code}", ex.MessagingErrorCode);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send FCM push notification.");
            return false;
        }
    }
}
