using Ajial.Application.Interfaces;
using Google.Apis.Auth.OAuth2;
using Google.Apis.Auth.OAuth2.Flows;
using Google.Apis.Auth.OAuth2.Responses;
using Google.Apis.Meet.v2;
using Google.Apis.Meet.v2.Data;
using Google.Apis.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Ajial.Infrastructure.Services;

/// <summary>
/// ينشئ روابط Google Meet عبر Google Meet REST API (v2) بإنشاء "مساحة" (Space) مفتوحة.
///
/// لماذا Meet API وليس Calendar API؟
///   رابط Meet المتولّد من حدث تقويم تكون صلاحيته الافتراضية "Trusted"، فيُطلب من أي شخص
///   غير مسجّل دخوله أو مسجّل بحساب مختلف عن حساب المضيف (nassereslam454@gmail.com) أن
///   "يطرق الباب" وينتظر الموافقة. الـ Calendar API لا يوفّر أي حقل لتغيير ذلك.
///   عبر Meet API نضبط AccessType = OPEN فيستطيع أي شخص لديه الرابط الانضمام مباشرةً
///   بلا طرق باب ولا موافقة.
///
/// آلية المصادقة: OAuth2 برمز تحديث (refresh token) لحساب Google عادي (consumer).
///
/// الإعدادات المطلوبة في appsettings (قسم GoogleMeet):
///   ClientId / ClientSecret  — من OAuth Client (نوع Desktop) في نفس مشروع GCP.
///   RefreshToken             — يجب توليده بنطاق meetings.space.created (راجع التعليمات).
///
/// ⚠ ملاحظة إعداد: رمز التحديث القديم (المخصّص للتقويم فقط) لن يعمل مع Meet API.
///   أعد توليد RefreshToken بموافقة تشمل النطاق:
///   https://www.googleapis.com/auth/meetings.space.created
/// </summary>
public class GoogleMeetService : IMeetingService
{
    private readonly ILogger<GoogleMeetService> _logger;
    private readonly Lazy<MeetService> _meet;

    public GoogleMeetService(IConfiguration configuration, ILogger<GoogleMeetService> logger)
    {
        _logger = logger;

        var section = configuration.GetSection("GoogleMeet");
        var clientId = section["ClientId"];
        var clientSecret = section["ClientSecret"];
        var refreshToken = section["RefreshToken"];

        // البناء كسول: لا نفشل عند الإقلاع إن لم تُضبط الإعدادات بعد — نفشل فقط عند أول استخدام فعلي.
        _meet = new Lazy<MeetService>(() =>
        {
            if (string.IsNullOrWhiteSpace(clientId) || string.IsNullOrWhiteSpace(clientSecret) || string.IsNullOrWhiteSpace(refreshToken))
                throw new InvalidOperationException(
                    "إعدادات Google Meet غير مكتملة. اضبط GoogleMeet:ClientId و ClientSecret و RefreshToken في appsettings.");

            var flow = new GoogleAuthorizationCodeFlow(new GoogleAuthorizationCodeFlow.Initializer
            {
                ClientSecrets = new ClientSecrets { ClientId = clientId, ClientSecret = clientSecret },
                // النطاق المطلوب لإنشاء مساحات Meet والتحكّم في صلاحية الدخول.
                Scopes = new[] { MeetService.Scope.MeetingsSpaceCreated }
            });

            var credential = new UserCredential(flow, "ajial-meet", new TokenResponse { RefreshToken = refreshToken });

            return new MeetService(new BaseClientService.Initializer
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
        // مساحة مفتوحة: أي شخص لديه الرابط ينضم مباشرةً بلا "طرق الباب" أو موافقة المضيف.
        //   AccessType = OPEN              → لا حاجة لموافقة المضيف على الضيوف.
        //   EntryPointAccess = ALL         → يمكن الانضمام من أي عميل/تطبيق Meet.
        var space = new Space
        {
            Config = new SpaceConfig
            {
                AccessType = "OPEN",
                EntryPointAccess = "ALL"
            }
        };

        var created = await _meet.Value.Spaces.Create(space).ExecuteAsync(cancellationToken);

        if (string.IsNullOrWhiteSpace(created.MeetingUri))
        {
            _logger.LogError("Google Meet space was created without a meeting URI. Space: {Space}", created.Name);
            throw new InvalidOperationException("لم يتم توليد رابط الاجتماع من Google.");
        }

        _logger.LogInformation("✅ Google Meet space created (OPEN access). Space: {Space}", created.Name);

        // نُرجع اسم المساحة (spaces/...) كمعرّف بدل معرّف حدث التقويم.
        return new MeetingInfo(created.MeetingUri, created.Name);
    }
}
