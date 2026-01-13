using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Validators;
using Ajial.Application.DTOs.VoiceNote;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Service;

/// <summary>
/// خدمة الملاحظات الصوتية - Voice Note Service
/// Handles voice note upload operations for children
/// </summary>
public class VoiceNoteService : IVoiceNoteService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IImageService _imageService;

    public VoiceNoteService(
        IUnitOfWork unitOfWork,
        IImageService imageService)
    {
        _unitOfWork = unitOfWork;
        _imageService = imageService;
    }

    /// <summary>
    /// Upload a voice note for a child
    /// </summary>
    public async Task<ApiResponse<UploadVoiceNoteResponseDto>> UploadVoiceNoteAsync(
        UploadVoiceNoteRequestDto request,
        Guid childId)
    {
        try
        {
            // Step 1: Validate request
            var validator = new UploadVoiceNoteRequestValidator();
            var (isValid, errors) = validator.Validate(request);

            if (!isValid)
            {
                return ApiResponse<UploadVoiceNoteResponseDto>.FailureResponse(
                    "فشل في رفع الملاحظة الصوتية",
                    errors
                );
            }

            // Step 2: Verify child exists and is active
            var child = await _unitOfWork.Children.GetByIdAsync(childId);
            if (child == null)
            {
                return ApiResponse<UploadVoiceNoteResponseDto>.FailureResponse(
                    "فشل في رفع الملاحظة الصوتية",
                    new List<string> { "الطفل غير موجود" }
                );
            }

            if (!child.IsActive)
            {
                return ApiResponse<UploadVoiceNoteResponseDto>.FailureResponse(
                    "فشل في رفع الملاحظة الصوتية",
                    new List<string> { "حساب الطفل غير نشط" }
                );
            }

            // Step 3: Generate title if not provided
            var title = string.IsNullOrWhiteSpace(request.Title)
                ? $"تسجيل {DateTime.UtcNow:yyyy-MM-dd HH:mm}"
                : request.Title.Trim();

            // Step 4: Generate unique filename
            var extension = Path.GetExtension(request.VoiceNote.FileName).ToLowerInvariant();
            var timestamp = DateTime.UtcNow.ToString("yyyyMMddHHmmss");
            var fileName = $"voicenote_{childId}_{timestamp}{extension}";

            // Step 5: Upload to Azure Blob Storage
            string blobUrl;
            try
            {
                blobUrl = await _imageService.UploadVoiceNoteAsync(request.VoiceNote, childId, fileName);
            }
            catch (Exception uploadEx)
            {
                return ApiResponse<UploadVoiceNoteResponseDto>.FailureResponse(
                    "فشل في رفع الملاحظة الصوتية",
                    new List<string> { $"فشل في رفع الملف: {uploadEx.Message}" }
                );
            }

            // Step 6: Create VoiceNote entity
            var voiceNote = new VoiceNote
            {
                Id = Guid.NewGuid(),
                ChildId = childId,
                Title = title,
                BlobUrl = blobUrl,
                FileName = fileName,
                FileSizeBytes = request.VoiceNote.Length,
                ContentType = request.VoiceNote.ContentType,
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };

            // Step 7: Save to database
            await _unitOfWork.VoiceNotes.AddAsync(voiceNote);
            await _unitOfWork.SaveChangesAsync();

            // Step 8: Create response
            var response = new UploadVoiceNoteResponseDto
            {
                VoiceNoteId = voiceNote.Id,
                Title = voiceNote.Title,
                BlobUrl = voiceNote.BlobUrl,
                FileSizeBytes = voiceNote.FileSizeBytes,
                CreatedAt = voiceNote.CreatedAt,
                Message = "تم رفع الملاحظة الصوتية بنجاح"
            };

            return ApiResponse<UploadVoiceNoteResponseDto>.SuccessResponse(
                response,
                "تم رفع الملاحظة الصوتية بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<UploadVoiceNoteResponseDto>.FailureResponse(
                "حدث خطأ أثناء رفع الملاحظة الصوتية",
                new List<string> { ex.Message }
            );
        }
    }

    /// <summary>
    /// Get all voice notes for a child
    /// </summary>
    public async Task<ApiResponse<List<VoiceNoteItemDto>>> GetVoiceNotesAsync(Guid childId)
    {
        try
        {
            // Step 1: Verify child exists and is active
            var child = await _unitOfWork.Children.GetByIdAsync(childId);
            if (child == null)
            {
                return ApiResponse<List<VoiceNoteItemDto>>.FailureResponse(
                    "فشل في جلب الملاحظات الصوتية",
                    new List<string> { "الطفل غير موجود" }
                );
            }

            if (!child.IsActive)
            {
                return ApiResponse<List<VoiceNoteItemDto>>.FailureResponse(
                    "فشل في جلب الملاحظات الصوتية",
                    new List<string> { "حساب الطفل غير نشط" }
                );
            }

            // Step 2: Get voice notes for this child only
            var voiceNotes = await _unitOfWork.VoiceNotes.GetByChildIdAsync(childId);

            // Step 3: Map to DTOs
            var response = voiceNotes.Select(v => new VoiceNoteItemDto
            {
                VoiceNoteId = v.Id,
                Title = v.Title,
                BlobUrl = v.BlobUrl,
                CreatedAt = v.CreatedAt
            }).ToList();

            return ApiResponse<List<VoiceNoteItemDto>>.SuccessResponse(
                response,
                "تم جلب الملاحظات الصوتية بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<List<VoiceNoteItemDto>>.FailureResponse(
                "حدث خطأ أثناء جلب الملاحظات الصوتية",
                new List<string> { ex.Message }
            );
        }
    }
}
