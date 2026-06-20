using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Ajial.Application.DTOs.Chat;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Ajial.API.Controllers;

/// <summary>
/// محادثة الاستشارة بين ولي الأمر والطبيب (المرحلة السابعة).
/// نقاط REST لتحميل السجل والإرسال (نصّ/مرفق). البثّ الفوري يتم عبر ChatHub على /hubs/chat.
/// متماثلة للطرفين: ولي الأمر والطبيب.
/// </summary>
[ApiController]
[Authorize(Roles = "Parent,Doctor,Specialist")]
[Route("api/chat")]
public class ChatController : ControllerBase
{
    private readonly IChatService _service;

    public ChatController(IChatService service) => _service = service;

    /// <summary>قائمة محادثاتي (صندوق الوارد).</summary>
    [HttpGet("conversations")]
    [ProducesResponseType(typeof(ApiResponse<List<ConversationListItemDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetConversations()
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<List<ConversationListItemDto>>();
        return ToActionResult(await _service.GetMyConversationsAsync(userId));
    }

    /// <summary>فتح محادثة حجز: معلومات الطرف الآخر + حالة النافذة + كل الرسائل.</summary>
    [HttpGet("bookings/{bookingId:guid}")]
    [ProducesResponseType(typeof(ApiResponse<ConversationResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetConversation(Guid bookingId)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<ConversationResponse>();
        return ToActionResult(await _service.GetConversationAsync(userId, bookingId));
    }

    /// <summary>إرسال رسالة نصية (يُخزَّن + يُبثّ فوراً للطرفين).</summary>
    [HttpPost("bookings/{bookingId:guid}/messages")]
    [ProducesResponseType(typeof(ApiResponse<ChatMessageDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SendText(Guid bookingId, [FromBody] SendTextMessageRequest request)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<ChatMessageDto>();
        return ToActionResult(await _service.SendTextMessageAsync(userId, bookingId, request.Content));
    }

    /// <summary>إرسال مرفق (صورة أو ملف) — multipart/form-data.</summary>
    [HttpPost("bookings/{bookingId:guid}/attachments")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<ChatMessageDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> SendAttachment(Guid bookingId, [FromForm] SendAttachmentRequest request)
    {
        if (!TryGetUserId(out var userId)) return UnauthorizedResponse<ChatMessageDto>();
        return ToActionResult(await _service.SendAttachmentAsync(userId, bookingId, request.File, request.Caption));
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private bool TryGetUserId(out Guid userId)
    {
        var claimValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst(JwtRegisteredClaimNames.Sub)?.Value
            ?? User.FindFirst("sub")?.Value;
        return Guid.TryParse(claimValue, out userId);
    }

    private ObjectResult UnauthorizedResponse<T>() =>
        StatusCode(StatusCodes.Status401Unauthorized,
            ApiResponse<T>.FailureResponse("غير مصرح", new List<string> { "غير مصرح" }));

    private ObjectResult ToActionResult<T>(ApiResponse<T> result)
    {
        if (result.Success) return Ok(result);
        if (result.Message.Contains("لم يتم العثور")) return NotFound(result);
        if (result.Message.Contains("غير مصرح")) return StatusCode(StatusCodes.Status403Forbidden, result);
        if (result.Message.Contains("مغلقة") || result.Message.Contains("لم يتم تأكيد") || result.Message.Contains("انتهت"))
            return StatusCode(StatusCodes.Status409Conflict, result);
        return BadRequest(result);
    }
}
