using Ajial.Application.DTOs.MedicalFile;

namespace Ajial.Application.Interfaces;

/// <summary>
/// مولّد ملف الـ PDF للملف الطبي الموحد للطفل.
/// التنفيذ يعيش في طبقة Infrastructure (يعتمد على مكتبة QuestPDF).
/// </summary>
public interface IMedicalFilePdfGenerator
{
    /// <summary>يرسم الملف الطبي ويعيد محتوى الـ PDF كمصفوفة بايت.</summary>
    byte[] Generate(MedicalFileData data);
}
