using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.VoiceNote;

namespace Ajial.Application.Interfaces;

/// <summary>
/// Service interface for Voice Note operations
/// </summary>
public interface IVoiceNoteService
{
    /// <summary>
    /// Upload a voice note for a child
    /// </summary>
    /// <param name="request">Voice note upload request</param>
    /// <param name="childId">Child ID from JWT claims</param>
    /// <returns>Upload response with voice note details</returns>
    Task<ApiResponse<UploadVoiceNoteResponseDto>> UploadVoiceNoteAsync(
        UploadVoiceNoteRequestDto request,
        Guid childId);

    /// <summary>
    /// Get all voice notes for a child
    /// </summary>
    /// <param name="childId">Child ID from JWT claims</param>
    /// <returns>List of voice notes belonging to the child</returns>
    Task<ApiResponse<List<VoiceNoteItemDto>>> GetVoiceNotesAsync(Guid childId);
}
