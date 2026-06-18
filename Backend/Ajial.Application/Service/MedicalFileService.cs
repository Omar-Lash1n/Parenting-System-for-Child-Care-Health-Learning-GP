using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.MedicalFile;
using Ajial.Application.Helpers;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Service;

/// <summary>
/// خدمة الملف الطبي الموحد للطفل (السجل الطبي): تجميع بيانات الطفل والتطعيمات،
/// توليد ملف الـ PDF، ورفعه إلى Azure Blob Storage.
/// </summary>
public class MedicalFileService : IMedicalFileService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMedicalFilePdfGenerator _pdfGenerator;
    private readonly IImageService _imageService;

    public MedicalFileService(
        IUnitOfWork unitOfWork,
        IMedicalFilePdfGenerator pdfGenerator,
        IImageService imageService)
    {
        _unitOfWork = unitOfWork;
        _pdfGenerator = pdfGenerator;
        _imageService = imageService;
    }

    public async Task<ApiResponse<MedicalFileResponse>> GenerateChildMedicalFileAsync(Guid childId, Guid parentUserId)
    {
        try
        {
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == parentUserId);
            if (parent == null)
                return ApiResponse<MedicalFileResponse>.FailureResponse("لم يتم العثور على حساب ولي الأمر");

            var child = await _unitOfWork.Children.GetByIdAsync(childId);
            if (child == null || child.ParentId != parent.Id)
                return ApiResponse<MedicalFileResponse>.FailureResponse("لم يتم العثور على الطفل أو لا ينتمي لهذا الحساب");

            var guardianName = (await _unitOfWork.Users.GetByIdAsync(parentUserId))?.FullName ?? "غير متوفر";

            var data = await BuildMedicalFileDataAsync(child, guardianName);
            var pdfBytes = _pdfGenerator.Generate(data);
            var url = await _imageService.UploadMedicalFileAsync(pdfBytes, child.Id);

            return ApiResponse<MedicalFileResponse>.SuccessResponse(new MedicalFileResponse
            {
                ChildId = child.Id,
                ChildName = child.FullName,
                FileNumber = data.FileNumber,
                FileUrl = url,
                GeneratedAt = DateTime.UtcNow
            }, "تم توليد الملف الطبي بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<MedicalFileResponse>.FailureResponse(
                "حدث خطأ في الخادم أثناء توليد الملف الطبي", new List<string> { ex.Message });
        }
    }

    public async Task<string?> TryGenerateShareableUrlAsync(Guid childId, Guid parentId)
    {
        try
        {
            var child = await _unitOfWork.Children.GetByIdAsync(childId);
            if (child == null || child.ParentId != parentId)
                return null;

            var guardian = await _unitOfWork.Parents.GetByIdAsync(parentId);
            var guardianName = guardian != null
                ? (await _unitOfWork.Users.GetByIdAsync(guardian.UserId))?.FullName ?? "غير متوفر"
                : "غير متوفر";

            var data = await BuildMedicalFileDataAsync(child, guardianName);
            var pdfBytes = _pdfGenerator.Generate(data);
            return await _imageService.UploadMedicalFileAsync(pdfBytes, child.Id);
        }
        catch
        {
            // لا نُفشل تدفّق الحجز إذا تعذّر توليد الملف الطبي
            return null;
        }
    }

    // ── تجميع البيانات ──
    private async Task<MedicalFileData> BuildMedicalFileDataAsync(Child child, string guardianName)
    {
        var (years, months, _) = CalculateExactAge(child.BirthDate);

        var data = new MedicalFileData
        {
            FileNumber = MedicalFileLabels.HealthFileNumber(child.Id),
            LastUpdatedLabel = MedicalFileLabels.ArabicDate(DateTime.UtcNow.AddHours(2)), // توقيت مصر UTC+2
            ChildName = child.FullName,
            AgeLabel = MedicalFileLabels.AgeLabel(years, months),
            BloodType = string.IsNullOrWhiteSpace(child.BloodType) ? "غير مسجلة" : MedicalFileLabels.LatinIsolate(child.BloodType!),
            GeneralGrowthLabel = "طبيعي", // قيمة ثابتة حالياً (تُحسب لاحقاً من منحنيات النمو)
            BirthDateLabel = MedicalFileLabels.ArabicDate(child.BirthDate),
            GuardianName = string.IsNullOrWhiteSpace(guardianName) ? "غير متوفر" : guardianName,
            EmergencyPhone = "غير متوفر",
        };

        // مؤشرات النمو (بدون عمود النسبة المئوية)
        data.Growth.Add(new MedicalGrowthRow { Metric = "الوزن", Value = child.Weight.HasValue ? $"{child.Weight} كجم" : "" });
        data.Growth.Add(new MedicalGrowthRow { Metric = "الطول", Value = child.Height.HasValue ? $"{child.Height} سم" : "" });
        data.Growth.Add(new MedicalGrowthRow { Metric = "محيط الرأس", Value = child.HeadCircumference.HasValue ? $"{child.HeadCircumference} سم" : "" });

        // التطعيمات
        var milestones = (await _unitOfWork.VaccinationMilestones.GetAllAsync())
            .Where(m => m.IsActive)
            .OrderBy(m => m.SortOrder).ThenBy(m => m.AgeInMonths)
            .ToList();

        var records = (await _unitOfWork.ChildVaccinations.FindAsync(cv => cv.ChildId == child.Id))
            .ToList();
        var recordByMilestone = records
            .GroupBy(r => r.VaccinationMilestoneId)
            .ToDictionary(g => g.Key, g => g.OrderByDescending(r => r.UpdatedAt).First());

        foreach (var m in milestones)
        {
            recordByMilestone.TryGetValue(m.Id, out var record);
            bool taken = record?.IsTaken ?? false;

            var name = string.IsNullOrWhiteSpace(m.VaccinesAr)
                ? m.NameAr
                : $"{m.NameAr} ({m.VaccinesAr})";

            var row = new MedicalVaccineRow
            {
                Name = name,
                TargetLabel = MedicalFileLabels.TargetAgeLabel(m.AgeInMonths),
                DateLabel = taken && record != null ? MedicalFileLabels.ArabicDate(record.RecordedAt) : "—",
                IsTaken = taken
            };

            if (string.Equals(m.Category, "Additional", StringComparison.OrdinalIgnoreCase))
                data.OptionalVaccines.Add(row);
            else
                data.MainVaccines.Add(row);
        }

        // السجل المرضي والتشخيصات السابقة — يُملأ في مرحلة لاحقة من ميزة الاستشارات
        // data.Consultations يبقى فارغاً ⇒ يُعرض كقسم بحالة فارغة.

        return data;
    }

    private static (int years, int months, int days) CalculateExactAge(DateTime birthDate)
    {
        DateTime today = DateTime.Today;
        int years = today.Year - birthDate.Year;
        int months = today.Month - birthDate.Month;
        int days = today.Day - birthDate.Day;

        if (days < 0)
        {
            months--;
            days += DateTime.DaysInMonth(today.Year, today.Month == 1 ? 12 : today.Month - 1);
        }
        if (months < 0)
        {
            years--;
            months += 12;
        }
        if (years < 0) return (0, 0, 0);

        return (years, months, days);
    }
}
