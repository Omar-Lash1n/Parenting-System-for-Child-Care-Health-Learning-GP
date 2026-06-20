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

    public async Task<string?> RegenerateForChildAsync(Guid childId)
    {
        try
        {
            var child = await _unitOfWork.Children.GetByIdAsync(childId);
            if (child == null) return null;

            var guardian = await _unitOfWork.Parents.GetByIdAsync(child.ParentId);
            var guardianName = guardian != null
                ? (await _unitOfWork.Users.GetByIdAsync(guardian.UserId))?.FullName ?? "غير متوفر"
                : "غير متوفر";

            var data = await BuildMedicalFileDataAsync(child, guardianName);
            var pdfBytes = _pdfGenerator.Generate(data);
            return await _imageService.UploadMedicalFileAsync(pdfBytes, child.Id);
        }
        catch
        {
            // لا نُفشل عملية السجل الإكلينيكي إذا تعذّر تحديث الملف الطبي
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

        // السجل المرضي والتشخيصات السابقة — تشخيصات الأطباء وروشتاتهم داخل التطبيق
        data.Consultations.AddRange(await BuildConsultationCardsAsync(child.Id));

        return data;
    }

    // ── تجميع بطاقات السجل المرضي (تشخيص + روشتة لكل حجز للطفل) ──
    private async Task<List<MedicalConsultationCard>> BuildConsultationCardsAsync(Guid childId)
    {
        var cards = new List<MedicalConsultationCard>();

        var bookings = (await _unitOfWork.Bookings.FindAsync(b => b.ChildId == childId)).ToList();
        if (bookings.Count == 0) return cards;

        var bookingIds = bookings.Select(b => b.Id).ToHashSet();

        var diagnosesByBooking = (await _unitOfWork.MedicalDiagnoses.FindAsync(d => bookingIds.Contains(d.BookingId)))
            .GroupBy(d => d.BookingId)
            .ToDictionary(g => g.Key, g => g.First());

        var medicinesByBooking = (await _unitOfWork.PrescriptionMedicines.FindAsync(m => bookingIds.Contains(m.BookingId)))
            .GroupBy(m => m.BookingId)
            .ToDictionary(g => g.Key, g => g.OrderBy(m => m.CreatedAt).ToList());

        // أسماء الأطباء وتخصصاتهم
        var specialistIds = bookings.Select(b => b.SpecialistId).Distinct().ToList();
        var specialists = (await _unitOfWork.Specialists.FindAsync(s => specialistIds.Contains(s.Id)))
            .ToDictionary(s => s.Id);
        var userIds = specialists.Values.Select(s => s.UserId).Distinct().ToList();
        var doctorNames = (await _unitOfWork.Users.FindAsync(u => userIds.Contains(u.Id)))
            .ToDictionary(u => u.Id, u => u.FullName);

        // أحدث الحجوزات أولاً
        foreach (var booking in bookings.OrderByDescending(b => b.AppointmentDate).ThenByDescending(b => b.CreatedAt))
        {
            diagnosesByBooking.TryGetValue(booking.Id, out var diagnosis);
            medicinesByBooking.TryGetValue(booking.Id, out var medicines);

            // نعرض الحجز في السجل فقط إذا سجّل الطبيب تشخيصاً أو روشتة
            if (diagnosis == null && (medicines == null || medicines.Count == 0)) continue;

            string specialty = "—";
            string doctorName = "غير متوفر";
            if (specialists.TryGetValue(booking.SpecialistId, out var sp))
            {
                if (!string.IsNullOrWhiteSpace(sp.Specialization)) specialty = sp.Specialization;
                if (doctorNames.TryGetValue(sp.UserId, out var name) && !string.IsNullOrWhiteSpace(name))
                    doctorName = $"د. {name}";
            }

            var card = new MedicalConsultationCard
            {
                Title = $"استشارة بتاريخ {MedicalFileLabels.ArabicDate(booking.AppointmentDate)}",
                Tag = specialty,
                DoctorName = doctorName,
                Diagnosis = diagnosis?.Description ?? "—",
                Prescription = (medicines ?? new List<PrescriptionMedicine>())
                    .Select(m => $"{m.MedicineName} — {m.Quantity} — {m.Timing}")
                    .ToList()
            };

            cards.Add(card);
        }

        return cards;
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
