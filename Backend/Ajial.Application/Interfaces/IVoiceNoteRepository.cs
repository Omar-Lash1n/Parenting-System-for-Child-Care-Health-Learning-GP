using Ajial.Domain.Entities;

namespace Ajial.Application.Interfaces;

/// <summary>
/// Repository interface for VoiceNote entity operations
/// </summary>
public interface IVoiceNoteRepository : IRepository<VoiceNote>
{
    /// <summary>
    /// Get all voice notes for a specific child
    /// </summary>
    Task<List<VoiceNote>> GetByChildIdAsync(Guid childId);

    /// <summary>
    /// Get active voice notes count for a child
    /// </summary>
    Task<int> GetCountByChildIdAsync(Guid childId);
}
