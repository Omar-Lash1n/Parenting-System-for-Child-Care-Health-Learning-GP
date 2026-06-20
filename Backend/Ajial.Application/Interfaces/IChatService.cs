using Ajial.Application.DTOs.Chat;
using Ajial.Application.DTOs.Common;
using Microsoft.AspNetCore.Http;

namespace Ajial.Application.Interfaces;

/// <summary>
/// محادثة الاستشارة بين ولي الأمر والطبيب المرتبطة بحجز.
/// Persists chat messages and (via <see cref="IChatRealtimeNotifier"/>) pushes them in real time.
/// </summary>
public interface IChatService
{
    /// <summary>قائمة محادثاتي (الحجوزات المؤكَّدة/المنتهية) لصندوق الوارد.</summary>
    Task<ApiResponse<List<ConversationListItemDto>>> GetMyConversationsAsync(Guid userId);

    /// <summary>فتح محادثة حجز: معلومات الطرف الآخر + حالة النافذة + الرسائل.</summary>
    Task<ApiResponse<ConversationResponse>> GetConversationAsync(Guid userId, Guid bookingId);

    /// <summary>إرسال رسالة نصية (يُخزِّن ثم يبثّ فوراً للطرفين).</summary>
    Task<ApiResponse<ChatMessageDto>> SendTextMessageAsync(Guid userId, Guid bookingId, string content);

    /// <summary>إرسال مرفق صورة/ملف (يرفعه إلى Blob ثم يُخزِّن ويبثّ).</summary>
    Task<ApiResponse<ChatMessageDto>> SendAttachmentAsync(Guid userId, Guid bookingId, IFormFile file, string? caption);

    /// <summary>تحقّق سريع: هل المستخدم طرف في محادثة هذا الحجز (للانضمام لمجموعة الـ Hub).</summary>
    Task<bool> CanAccessConversationAsync(Guid userId, Guid bookingId);
}
