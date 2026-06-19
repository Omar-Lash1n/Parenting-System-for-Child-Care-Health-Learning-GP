using Ajial.Application.Interfaces;
using Google.Apis.Auth.OAuth2;
using Google.Apis.Auth.OAuth2.Flows;
using Google.Apis.Auth.OAuth2.Responses;
using Google.Apis.Calendar.v3;
using Google.Apis.Calendar.v3.Data;
using Google.Apis.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Ajial.Infrastructure.Services;

/// <summary>
/// ينشئ روابط Google Meet عبر Google Calendar API.
///
/// آلية المصادقة: OAuth2 برمز تحديث (refresh token) لحساب Google عادي (consumer)،
/// لأن حساب الخدمة (service account) على مشروع غير مرتبط بـ Google Workspace لا يستطيع
/// توليد روابط Meet. يُنشأ الحدث في تقويم هذا الحساب فيتولّد رابط Meet تلقائياً.
///
/// الإعدادات المطلوبة في appsettings (قسم GoogleMeet):
///   ClientId / ClientSecret  — من OAuth Client (نوع Desktop) في نفس مشروع GCP.
///   RefreshToken             — يُولّد مرة واحدة عبر موافقة المستخدم (راجع تعليمات الإعداد).
///   CalendarId               — اختياري، الافتراضي "primary".
/// </summary>
public class GoogleMeetService : IMeetingService
{
    private const string TimeZoneId = "Africa/Cairo";
    private static readonly TimeSpan EgyptOffset = TimeSpan.FromHours(2); // متوافق مع WorkingHoursHelper.EgyptNow (UTC+2)

    private readonly ILogger<GoogleMeetService> _logger;
    private readonly string _calendarId;
    private readonly Lazy<CalendarService> _calendar;

    public GoogleMeetService(IConfiguration configuration, ILogger<GoogleMeetService> logger)
    {
        _logger = logger;

        var section = configuration.GetSection("GoogleMeet");
        var clientId = section["ClientId"];
        var clientSecret = section["ClientSecret"];
        var refreshToken = section["RefreshToken"];
        _calendarId = string.IsNullOrWhiteSpace(section["CalendarId"]) ? "primary" : section["CalendarId"]!;

        // البناء كسول: لا نفشل عند الإقلاع إن لم تُضبط الإعدادات بعد — نفشل فقط عند أول استخدام فعلي.
        _calendar = new Lazy<CalendarService>(() =>
        {
            if (string.IsNullOrWhiteSpace(clientId) || string.IsNullOrWhiteSpace(clientSecret) || string.IsNullOrWhiteSpace(refreshToken))
                throw new InvalidOperationException(
                    "إعدادات Google Meet غير مكتملة. اضبط GoogleMeet:ClientId و ClientSecret و RefreshToken في appsettings.");

            var flow = new GoogleAuthorizationCodeFlow(new GoogleAuthorizationCodeFlow.Initializer
            {
                ClientSecrets = new ClientSecrets { ClientId = clientId, ClientSecret = clientSecret },
                Scopes = new[] { CalendarService.Scope.Calendar }
            });

            var credential = new UserCredential(flow, "ajial-meet", new TokenResponse { RefreshToken = refreshToken });

            return new CalendarService(new BaseClientService.Initializer
            {
                HttpClientInitializer = credential,
                ApplicationName = "Ajial"
            });
        });
    }

    public async Task<MeetingInfo> CreateMeetingAsync(
        string title,
        string? description,
        DateTime startEgyptLocal,
        DateTime endEgyptLocal,
        CancellationToken cancellationToken = default)
    {
        var startOffset = new DateTimeOffset(DateTime.SpecifyKind(startEgyptLocal, DateTimeKind.Unspecified), EgyptOffset);
        var endOffset = new DateTimeOffset(DateTime.SpecifyKind(endEgyptLocal, DateTimeKind.Unspecified), EgyptOffset);

        var newEvent = new Event
        {
            Summary = title,
            Description = description,
            Start = new EventDateTime { DateTimeRaw = startOffset.ToString("yyyy-MM-ddTHH:mm:sszzz"), TimeZone = TimeZoneId },
            End = new EventDateTime { DateTimeRaw = endOffset.ToString("yyyy-MM-ddTHH:mm:sszzz"), TimeZone = TimeZoneId },
            ConferenceData = new ConferenceData
            {
                CreateRequest = new CreateConferenceRequest
                {
                    RequestId = Guid.NewGuid().ToString("N"),
                    ConferenceSolutionKey = new ConferenceSolutionKey { Type = "hangoutsMeet" }
                }
            }
        };

        var request = _calendar.Value.Events.Insert(newEvent, _calendarId);
        request.ConferenceDataVersion = 1;

        var created = await request.ExecuteAsync(cancellationToken);

        var joinUrl = ExtractMeetLink(created);
        if (string.IsNullOrWhiteSpace(joinUrl))
        {
            _logger.LogError("Google Meet link was not generated for event {EventId}. " +
                             "Verify the configured Google account can create Meet links.", created.Id);
            throw new InvalidOperationException("لم يتم توليد رابط الاجتماع من Google.");
        }

        _logger.LogInformation("✅ Google Meet created. EventId: {EventId}", created.Id);
        return new MeetingInfo(joinUrl, created.Id);
    }

    private static string? ExtractMeetLink(Event ev)
    {
        if (!string.IsNullOrWhiteSpace(ev.HangoutLink))
            return ev.HangoutLink;

        var video = ev.ConferenceData?.EntryPoints?
            .FirstOrDefault(e => e.EntryPointType == "video" && !string.IsNullOrWhiteSpace(e.Uri));
        return video?.Uri;
    }
}
