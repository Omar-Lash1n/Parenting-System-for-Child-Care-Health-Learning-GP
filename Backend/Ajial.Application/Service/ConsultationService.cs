using System.Globalization;
using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Consultation;
using Ajial.Application.Helpers;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace Ajial.Application.Service;

public class ConsultationService : IConsultationService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IImageService _imageService;
    private readonly IMedicalFileService _medicalFileService;

    private const int SearchHorizonDays = 60; // أقصى عدد أيام للبحث عن أقرب موعد
    private const int SessionRatingStarsReward = 250; // نجوم المكافأة مقابل تقييم الجلسة

    public ConsultationService(IUnitOfWork unitOfWork, IImageService imageService, IMedicalFileService medicalFileService)
    {
        _unitOfWork = unitOfWork;
        _imageService = imageService;
        _medicalFileService = medicalFileService;
    }

    // ── الاكتشاف ───────────────────────────────────────────────────────────────

    public async Task<ApiResponse<List<AvailableDoctorResponse>>> GetAvailableDoctorsAsync(string? search, string? specialization)
    {
        try
        {
            var approvedClinics = (await _unitOfWork.Clinics.FindAsync(c => c.Status == ClinicStatus.Approved)).ToList();
            var approvedRemotes = (await _unitOfWork.RemoteConsultations.FindAsync(r => r.Status == RemoteConsultationStatus.Approved)).ToList();

            var clinicBySpecialist = approvedClinics
                .GroupBy(c => c.SpecialistId)
                .ToDictionary(g => g.Key, g => g.OrderBy(c => c.CreatedAt).First());
            var remoteBySpecialist = approvedRemotes
                .GroupBy(r => r.SpecialistId)
                .ToDictionary(g => g.Key, g => g.OrderBy(r => r.CreatedAt).First());

            var availableIds = clinicBySpecialist.Keys.Union(remoteBySpecialist.Keys).ToHashSet();
            if (availableIds.Count == 0)
                return ApiResponse<List<AvailableDoctorResponse>>.SuccessResponse(new List<AvailableDoctorResponse>(), "لا يوجد أطباء متاحون حالياً");

            var specialists = (await _unitOfWork.Specialists.GetAllAsync(q => q.Include(s => s.User)))
                .Where(s => s.Status == SpecialistStatus.Approved && availableIds.Contains(s.Id))
                .ToList();

            var list = specialists.Select(s =>
            {
                clinicBySpecialist.TryGetValue(s.Id, out var clinic);
                remoteBySpecialist.TryGetValue(s.Id, out var remote);
                return new AvailableDoctorResponse
                {
                    SpecialistId = s.Id,
                    DoctorName = s.User?.FullName ?? string.Empty,
                    PhotoUrl = s.PersonalPhotoUrl,
                    Specialization = s.Specialization,
                    HasClinic = clinic != null,
                    HasRemote = remote != null,
                    ClinicExaminationPrice = clinic?.ExaminationPrice,
                    RemoteSessionPrice = remote?.SessionPrice
                };
            });

            if (!string.IsNullOrWhiteSpace(specialization))
                list = list.Where(d => d.Specialization == specialization.Trim());

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search.Trim();
                list = list.Where(d => d.DoctorName.Contains(term, StringComparison.OrdinalIgnoreCase)
                                       || d.Specialization.Contains(term, StringComparison.OrdinalIgnoreCase));
            }

            return ApiResponse<List<AvailableDoctorResponse>>.SuccessResponse(
                list.OrderBy(d => d.DoctorName).ToList(), "تم جلب الأطباء المتاحين بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<List<AvailableDoctorResponse>>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<List<SpecialtyChipResponse>>> GetSpecialtyChipsAsync()
    {
        try
        {
            var doctors = await GetAvailableDoctorsAsync(null, null);
            var chips = (doctors.Data ?? new List<AvailableDoctorResponse>())
                .Where(d => !string.IsNullOrWhiteSpace(d.Specialization))
                .GroupBy(d => d.Specialization)
                .Select(g => new SpecialtyChipResponse { Specialization = g.Key, DoctorCount = g.Count() })
                .OrderByDescending(c => c.DoctorCount)
                .ToList();

            return ApiResponse<List<SpecialtyChipResponse>>.SuccessResponse(chips, "تم جلب التخصصات بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<List<SpecialtyChipResponse>>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<DoctorProfileResponse>> GetDoctorProfileAsync(Guid specialistId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.Id == specialistId, "User");
            if (specialist == null || specialist.Status != SpecialistStatus.Approved)
                return ApiResponse<DoctorProfileResponse>.FailureResponse("لم يتم العثور على الطبيب");

            var clinic = await GetApprovedClinicAsync(specialistId);
            var remote = await GetApprovedRemoteAsync(specialistId);
            if (clinic == null && remote == null)
                return ApiResponse<DoctorProfileResponse>.FailureResponse("لم يتم العثور على الطبيب");

            string? governorateName = clinic?.GovernorateId != null
                ? (await _unitOfWork.Cities.GetByIdAsync(clinic.GovernorateId.Value))?.NameAr
                : null;

            return ApiResponse<DoctorProfileResponse>.SuccessResponse(new DoctorProfileResponse
            {
                SpecialistId = specialist.Id,
                DoctorName = specialist.User?.FullName ?? string.Empty,
                PhotoUrl = specialist.PersonalPhotoUrl,
                Specialization = specialist.Specialization,
                HasClinic = clinic != null,
                HasRemote = remote != null,
                ClinicExaminationPrice = clinic?.ExaminationPrice,
                RemoteSessionPrice = remote?.SessionPrice,
                ClinicAddress = clinic?.Address,
                ClinicGovernorateName = governorateName
            }, "تم جلب ملف الطبيب بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<DoctorProfileResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<BookingInfoResponse>> GetBookingInfoAsync(Guid specialistId)
    {
        try
        {
            var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.Id == specialistId, "User");
            if (specialist == null || specialist.Status != SpecialistStatus.Approved)
                return ApiResponse<BookingInfoResponse>.FailureResponse("لم يتم العثور على الطبيب");

            var clinic = await GetApprovedClinicAsync(specialistId);
            var remote = await GetApprovedRemoteAsync(specialistId);
            if (clinic == null && remote == null)
                return ApiResponse<BookingInfoResponse>.FailureResponse("لا توجد خدمات متاحة لهذا الطبيب");

            string? governorateName = clinic?.GovernorateId != null
                ? (await _unitOfWork.Cities.GetByIdAsync(clinic.GovernorateId.Value))?.NameAr
                : null;

            var response = new BookingInfoResponse
            {
                SpecialistId = specialist.Id,
                DoctorName = specialist.User?.FullName ?? string.Empty,
                PhotoUrl = specialist.PersonalPhotoUrl,
                Specialization = specialist.Specialization,
                Clinic = clinic == null ? null : new ClinicServiceInfo
                {
                    ClinicId = clinic.Id,
                    ExaminationPrice = clinic.ExaminationPrice,
                    ConsultationPrice = clinic.ConsultationPrice,
                    WorkingHoursJson = clinic.WorkingHoursJson,
                    Address = clinic.Address,
                    GovernorateName = governorateName
                },
                Remote = remote == null ? null : new RemoteServiceInfo
                {
                    ConsultationId = remote.Id,
                    SessionPrice = remote.SessionPrice,
                    SessionDurationMinutes = remote.SessionDurationMinutes,
                    WaitingPeriodMinutes = remote.WaitingPeriodMinutes,
                    WorkingHoursJson = remote.WorkingHoursJson
                }
            };

            return ApiResponse<BookingInfoResponse>.SuccessResponse(response, "تم جلب بيانات الحجز بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<BookingInfoResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<DaySlotsResponse>> GetSlotsAsync(Guid specialistId, string serviceType, string date)
    {
        try
        {
            if (!TryParseServiceType(serviceType, out var type))
                return ApiResponse<DaySlotsResponse>.FailureResponse("نوع الخدمة غير صحيح");

            if (!DateTime.TryParseExact(date, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var day))
                return ApiResponse<DaySlotsResponse>.FailureResponse("تاريخ غير صحيح، الصيغة المطلوبة yyyy-MM-dd");
            day = day.Date;

            var response = new DaySlotsResponse { Date = date, ServiceType = ConsultationLabels.ServiceTypeKey(type) };
            var now = WorkingHoursHelper.EgyptNow();

            if (type == BookingServiceType.RemoteConsultation)
            {
                var remote = await GetApprovedRemoteAsync(specialistId);
                if (remote == null || !remote.SessionDurationMinutes.HasValue)
                    return ApiResponse<DaySlotsResponse>.SuccessResponse(response, "لا توجد جلسات اون لاين متاحة");

                var slots = WorkingHoursHelper.GenerateRemoteSlots(
                    remote.WorkingHoursJson, day, remote.SessionDurationMinutes.Value, remote.WaitingPeriodMinutes ?? 0);
                var booked = await GetBookedRemoteStartTimesAsync(specialistId, day);

                foreach (var (start, end) in slots)
                {
                    if (day.Date == now.Date && start <= now.TimeOfDay) continue; // تخطّي المواعيد التي فاتت اليوم
                    response.Slots.Add(new SlotDto
                    {
                        StartTime = WorkingHoursHelper.Format(start),
                        EndTime = WorkingHoursHelper.Format(end),
                        IsBooked = booked.Contains(start)
                    });
                }
                response.IsAvailable = response.Slots.Count > 0;
            }
            else
            {
                var clinic = await GetApprovedClinicAsync(specialistId);
                if (clinic == null)
                    return ApiResponse<DaySlotsResponse>.SuccessResponse(response, "لا توجد عيادة متاحة");

                var periods = WorkingHoursHelper.GetPeriodsForDate(clinic.WorkingHoursJson, day);
                response.WorkingPeriods = periods
                    .Select(p => new PeriodDto { From = WorkingHoursHelper.Format(p.From), To = WorkingHoursHelper.Format(p.To) })
                    .ToList();
                response.WorkingHoursText = WorkingHoursHelper.BuildWorkingHoursText(periods);
                response.IsAvailable = periods.Count > 0
                    && !(day.Date == now.Date && now.TimeOfDay > periods.Max(p => p.To));
            }

            return ApiResponse<DaySlotsResponse>.SuccessResponse(response, "تم جلب المواعيد بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<DaySlotsResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<NearestSlotResponse>> GetNearestSlotAsync(Guid specialistId, string serviceType)
    {
        try
        {
            if (!TryParseServiceType(serviceType, out var type))
                return ApiResponse<NearestSlotResponse>.FailureResponse("نوع الخدمة غير صحيح");

            var response = new NearestSlotResponse { ServiceType = ConsultationLabels.ServiceTypeKey(type), Found = false };
            var now = WorkingHoursHelper.EgyptNow();

            if (type == BookingServiceType.RemoteConsultation)
            {
                var remote = await GetApprovedRemoteAsync(specialistId);
                if (remote == null || !remote.SessionDurationMinutes.HasValue)
                    return ApiResponse<NearestSlotResponse>.SuccessResponse(response, "لا توجد جلسات اون لاين متاحة");

                for (int i = 0; i <= SearchHorizonDays; i++)
                {
                    var day = now.Date.AddDays(i);
                    var slots = WorkingHoursHelper.GenerateRemoteSlots(
                        remote.WorkingHoursJson, day, remote.SessionDurationMinutes.Value, remote.WaitingPeriodMinutes ?? 0);
                    if (slots.Count == 0) continue;

                    var booked = await GetBookedRemoteStartTimesAsync(specialistId, day);
                    var candidate = slots
                        .Where(s => (day + s.Start) > now && !booked.Contains(s.Start))
                        .OrderBy(s => s.Start)
                        .Select(s => ((TimeSpan Start, TimeSpan End)?)s)
                        .FirstOrDefault();

                    if (candidate.HasValue)
                    {
                        response.Found = true;
                        response.Date = day.ToString("yyyy-MM-dd");
                        response.StartTime = WorkingHoursHelper.Format(candidate.Value.Start);
                        response.EndTime = WorkingHoursHelper.Format(candidate.Value.End);
                        break;
                    }
                }
            }
            else
            {
                var clinic = await GetApprovedClinicAsync(specialistId);
                if (clinic == null)
                    return ApiResponse<NearestSlotResponse>.SuccessResponse(response, "لا توجد عيادة متاحة");

                for (int i = 0; i <= SearchHorizonDays; i++)
                {
                    var day = now.Date.AddDays(i);
                    var periods = WorkingHoursHelper.GetPeriodsForDate(clinic.WorkingHoursJson, day);
                    if (periods.Count == 0) continue;
                    if (day.Date == now.Date && now.TimeOfDay > periods.Max(p => p.To)) continue;

                    response.Found = true;
                    response.Date = day.ToString("yyyy-MM-dd");
                    response.WorkingHoursText = WorkingHoursHelper.BuildWorkingHoursText(periods);
                    break;
                }
            }

            return ApiResponse<NearestSlotResponse>.SuccessResponse(response,
                response.Found ? "تم العثور على أقرب موعد" : "لا توجد مواعيد متاحة قريباً");
        }
        catch (Exception ex)
        {
            return ApiResponse<NearestSlotResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── الحجز والدفع ───────────────────────────────────────────────────────────

    public async Task<ApiResponse<List<PatientResponse>>> GetPatientsAsync(Guid userId)
    {
        try
        {
            var (parent, user, error) = await ResolveParentAsync<List<PatientResponse>>(userId);
            if (error != null) return error;

            var patients = new List<PatientResponse>
            {
                new() { ChildId = null, Name = user!.FullName, ImageUrl = parent!.ProfileImageUrl, IsSelf = true }
            };

            var children = (await _unitOfWork.Children.FindAsync(c => c.ParentId == parent.Id && c.IsActive))
                .OrderBy(c => c.FullName);
            patients.AddRange(children.Select(c => new PatientResponse
            {
                ChildId = c.Id,
                Name = c.FullName,
                ImageUrl = c.ProfileImageUrl,
                IsSelf = false
            }));

            return ApiResponse<List<PatientResponse>>.SuccessResponse(patients, "تم جلب قائمة المرضى بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<List<PatientResponse>>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<PaymentMethodsResponse>> GetPaymentMethodsAsync()
    {
        try
        {
            var settings = (await _unitOfWork.PaymentSettings.GetAllAsync())
                .ToDictionary(s => s.Key, s => s.Value);

            return ApiResponse<PaymentMethodsResponse>.SuccessResponse(new PaymentMethodsResponse
            {
                VodafoneCashNumber = settings.GetValueOrDefault(ConsultationLabels.VodafoneCashKey, ConsultationLabels.DefaultWalletNumber),
                InstaPayNumber = settings.GetValueOrDefault(ConsultationLabels.InstaPayKey, ConsultationLabels.DefaultWalletNumber)
            }, "تم جلب بيانات الدفع بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<PaymentMethodsResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<BookingSummaryResponse>> CreateBookingAsync(Guid userId, CreateBookingRequest request)
    {
        try
        {
            var (parent, user, error) = await ResolveParentAsync<BookingSummaryResponse>(userId);
            if (error != null) return error;

            if (!Enum.IsDefined(typeof(BookingServiceType), request.ServiceType))
                return ApiResponse<BookingSummaryResponse>.FailureResponse("نوع الخدمة غير صحيح");
            var serviceType = (BookingServiceType)request.ServiceType;

            var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.Id == request.SpecialistId, "User");
            if (specialist == null || specialist.Status != SpecialistStatus.Approved)
                return ApiResponse<BookingSummaryResponse>.FailureResponse("الطبيب غير متاح");

            // الخدمة والسعر
            decimal price;
            Guid? clinicId = null, remoteId = null;
            int? durationMinutes = null, waitingMinutes = null;
            string? workingHoursJson;

            if (serviceType == BookingServiceType.Clinic)
            {
                var clinic = await GetApprovedClinicAsync(specialist.Id);
                if (clinic == null) return ApiResponse<BookingSummaryResponse>.FailureResponse("خدمة العيادة غير متاحة لهذا الطبيب");
                if (!clinic.ExaminationPrice.HasValue) return ApiResponse<BookingSummaryResponse>.FailureResponse("سعر الكشف غير محدد");
                price = clinic.ExaminationPrice.Value;
                clinicId = clinic.Id;
                workingHoursJson = clinic.WorkingHoursJson;
            }
            else
            {
                var remote = await GetApprovedRemoteAsync(specialist.Id);
                if (remote == null) return ApiResponse<BookingSummaryResponse>.FailureResponse("خدمة الكشف عن بعد غير متاحة لهذا الطبيب");
                if (!remote.SessionPrice.HasValue || !remote.SessionDurationMinutes.HasValue)
                    return ApiResponse<BookingSummaryResponse>.FailureResponse("بيانات الجلسة اون لاين غير مكتملة");
                price = remote.SessionPrice.Value;
                remoteId = remote.Id;
                durationMinutes = remote.SessionDurationMinutes.Value;
                waitingMinutes = remote.WaitingPeriodMinutes ?? 0;
                workingHoursJson = remote.WorkingHoursJson;
            }

            // المريض (طفل مفعّل أو ولي الأمر نفسه)
            Guid? childId = null;
            string patientName;
            if (request.ChildId.HasValue)
            {
                var child = await _unitOfWork.Children.GetByIdAsync(request.ChildId.Value);
                if (child == null || child.ParentId != parent!.Id)
                    return ApiResponse<BookingSummaryResponse>.FailureResponse("الطفل غير موجود");
                if (!child.IsActive)
                    return ApiResponse<BookingSummaryResponse>.FailureResponse("لا يمكن الحجز لطفل غير مفعّل");
                childId = child.Id;
                patientName = child.FullName;
            }
            else
            {
                patientName = user!.FullName;
            }

            // التاريخ
            if (!DateTime.TryParseExact(request.SlotDate, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var date))
                return ApiResponse<BookingSummaryResponse>.FailureResponse("تاريخ غير صحيح، الصيغة المطلوبة yyyy-MM-dd");
            date = date.Date;
            var now = WorkingHoursHelper.EgyptNow();
            if (date < now.Date)
                return ApiResponse<BookingSummaryResponse>.FailureResponse("لا يمكن الحجز في تاريخ ماضٍ");

            TimeSpan? startTime = null, endTime = null;

            if (serviceType == BookingServiceType.RemoteConsultation)
            {
                var parsedStart = WorkingHoursHelper.ParseTime(request.StartTime);
                if (!parsedStart.HasValue)
                    return ApiResponse<BookingSummaryResponse>.FailureResponse("وقت الجلسة مطلوب وبصيغة صحيحة HH:mm");

                var slots = WorkingHoursHelper.GenerateRemoteSlots(workingHoursJson, date, durationMinutes!.Value, waitingMinutes!.Value);
                var matches = slots.Where(s => s.Start == parsedStart.Value).ToList();
                if (matches.Count == 0)
                    return ApiResponse<BookingSummaryResponse>.FailureResponse("الموعد المختار غير متاح");

                startTime = matches[0].Start;
                endTime = matches[0].End;

                if (date + startTime.Value <= now)
                    return ApiResponse<BookingSummaryResponse>.FailureResponse("هذا الموعد قد فات، اختر موعداً آخر");

                var booked = await GetBookedRemoteStartTimesAsync(specialist.Id, date);
                if (booked.Contains(startTime.Value))
                    return ApiResponse<BookingSummaryResponse>.FailureResponse("تم حجز هذا الموعد بالفعل");
            }
            else
            {
                var periods = WorkingHoursHelper.GetPeriodsForDate(workingHoursJson, date);
                if (periods.Count == 0)
                    return ApiResponse<BookingSummaryResponse>.FailureResponse("لا توجد مواعيد عمل للعيادة في هذا اليوم");
                if (date.Date == now.Date && now.TimeOfDay > periods.Max(p => p.To))
                    return ApiResponse<BookingSummaryResponse>.FailureResponse("انتهت مواعيد العمل لهذا اليوم");
            }

            var booking = new Booking
            {
                Id = Guid.NewGuid(),
                ParentId = parent!.Id,
                ChildId = childId,
                SpecialistId = specialist.Id,
                ServiceType = serviceType,
                ClinicId = clinicId,
                RemoteConsultationId = remoteId,
                AppointmentDate = date,
                StartTime = startTime,
                EndTime = endTime,
                DurationMinutes = durationMinutes,
                Price = price,
                ComplaintDescription = string.IsNullOrWhiteSpace(request.ComplaintDescription) ? null : request.ComplaintDescription.Trim(),
                ShareMedicalFile = request.ShareMedicalFile,
                Status = BookingStatus.PendingPayment,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.Bookings.AddAsync(booking);

            // مشاركة الملف الطبي: توليد الملف الطبي للطفل وحفظ رابطه مع الحجز (الطفل فقط، وليس ولي الأمر)
            if (request.ShareMedicalFile && childId.HasValue)
            {
                booking.MedicalFileUrl = await _medicalFileService.TryGenerateShareableUrlAsync(childId.Value, parent!.Id);
            }

            if (request.Attachments != null)
            {
                foreach (var file in request.Attachments.Where(f => f != null && f.Length > 0))
                {
                    var url = await _imageService.UploadBookingAttachmentAsync(file, parent.Id);
                    await _unitOfWork.BookingAttachments.AddAsync(new BookingAttachment
                    {
                        Id = Guid.NewGuid(),
                        BookingId = booking.Id,
                        ImageUrl = url,
                        CreatedAt = DateTime.UtcNow
                    });
                }
            }

            try
            {
                await _unitOfWork.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                // الحارس النهائي ضد التزامن — تم أخذ الموعد بين الفحص والحفظ
                return ApiResponse<BookingSummaryResponse>.FailureResponse("تم حجز هذا الموعد بالفعل");
            }

            return ApiResponse<BookingSummaryResponse>.SuccessResponse(
                BuildSummary(booking, specialist, patientName), "تم إنشاء الحجز، يمكنك الآن الانتقال للدفع");
        }
        catch (Exception ex)
        {
            return ApiResponse<BookingSummaryResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<List<AttachmentDto>>> AddAttachmentAsync(Guid userId, Guid bookingId, IFormFile file)
    {
        try
        {
            var (booking, parent, error) = await ResolveBookingAsync<List<AttachmentDto>>(userId, bookingId);
            if (error != null) return error;

            if (booking!.Status != BookingStatus.PendingPayment)
                return ApiResponse<List<AttachmentDto>>.FailureResponse("لا يمكن تعديل المرفقات في الحالة الحالية");
            if (file == null || file.Length == 0)
                return ApiResponse<List<AttachmentDto>>.FailureResponse("الملف مطلوب");

            var url = await _imageService.UploadBookingAttachmentAsync(file, parent!.Id);
            await _unitOfWork.BookingAttachments.AddAsync(new BookingAttachment
            {
                Id = Guid.NewGuid(),
                BookingId = booking.Id,
                ImageUrl = url,
                CreatedAt = DateTime.UtcNow
            });
            await _unitOfWork.SaveChangesAsync();

            return await GetAttachmentsResponseAsync(booking.Id, "تم رفع المرفق بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<List<AttachmentDto>>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<List<AttachmentDto>>> DeleteAttachmentAsync(Guid userId, Guid bookingId, Guid attachmentId)
    {
        try
        {
            var (booking, _, error) = await ResolveBookingAsync<List<AttachmentDto>>(userId, bookingId);
            if (error != null) return error;

            if (booking!.Status != BookingStatus.PendingPayment)
                return ApiResponse<List<AttachmentDto>>.FailureResponse("لا يمكن تعديل المرفقات في الحالة الحالية");

            var attachment = await _unitOfWork.BookingAttachments.GetFirstOrDefaultAsync(a => a.Id == attachmentId && a.BookingId == booking.Id);
            if (attachment == null)
                return ApiResponse<List<AttachmentDto>>.FailureResponse("لم يتم العثور على المرفق");

            await _imageService.DeleteBlobByUrlAsync(attachment.ImageUrl);
            await _unitOfWork.BookingAttachments.DeleteAsync(attachment);
            await _unitOfWork.SaveChangesAsync();

            return await GetAttachmentsResponseAsync(booking.Id, "تم حذف المرفق بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<List<AttachmentDto>>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<BookingSummaryResponse>> SubmitPaymentAsync(Guid userId, Guid bookingId, SubmitPaymentRequest request)
    {
        try
        {
            var (booking, parent, error) = await ResolveBookingAsync<BookingSummaryResponse>(userId, bookingId);
            if (error != null) return error;

            if (booking!.Status != BookingStatus.PendingPayment)
                return ApiResponse<BookingSummaryResponse>.FailureResponse("لا يمكن إرسال الإيصال في الحالة الحالية");

            if (!Enum.IsDefined(typeof(PaymentMethod), request.Method))
                return ApiResponse<BookingSummaryResponse>.FailureResponse("طريقة الدفع غير صحيحة");
            if (request.Receipt == null || request.Receipt.Length == 0)
                return ApiResponse<BookingSummaryResponse>.FailureResponse("صورة إيصال التحويل مطلوبة");

            var receiptUrl = await _imageService.UploadPaymentReceiptAsync(request.Receipt, parent!.Id);

            await _unitOfWork.Payments.AddAsync(new Payment
            {
                Id = Guid.NewGuid(),
                BookingId = booking.Id,
                ParentId = parent.Id,
                Method = (PaymentMethod)request.Method,
                Amount = booking.Price,
                ReceiptImageUrl = receiptUrl,
                Status = PaymentStatus.Pending,
                CreatedAt = DateTime.UtcNow
            });

            booking.Status = BookingStatus.PendingReview;
            booking.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Bookings.UpdateAsync(booking);
            await _unitOfWork.SaveChangesAsync();

            var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.Id == booking.SpecialistId, "User");
            var patientName = await ResolvePatientNameAsync(booking, parent);

            return ApiResponse<BookingSummaryResponse>.SuccessResponse(
                BuildSummary(booking, specialist, patientName),
                "تم إرسال طلب الحجز بنجاح، سيتم الرد خلال 20 دقيقة");
        }
        catch (Exception ex)
        {
            return ApiResponse<BookingSummaryResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── حجوزاتي والمعاملات المالية ─────────────────────────────────────────────

    public async Task<ApiResponse<List<BookingListItemResponse>>> GetMyBookingsAsync(Guid userId, int? status)
    {
        try
        {
            var (parent, user, error) = await ResolveParentAsync<List<BookingListItemResponse>>(userId);
            if (error != null) return error;

            var bookings = (await _unitOfWork.Bookings.FindAsync(b => b.ParentId == parent!.Id)).ToList();
            await AutoCompleteEndedRemoteSessionsAsync(bookings);
            if (status.HasValue)
            {
                if (!Enum.IsDefined(typeof(BookingStatus), status.Value))
                    return ApiResponse<List<BookingListItemResponse>>.FailureResponse("حالة غير صحيحة");
                bookings = bookings.Where(b => (int)b.Status == status.Value).ToList();
            }
            bookings = bookings.OrderByDescending(b => b.CreatedAt).ToList();

            var (specialistMap, childMap) = await LoadBookingLookupsAsync(bookings);

            var items = bookings.Select(b =>
            {
                specialistMap.TryGetValue(b.SpecialistId, out var sp);
                var item = MapToListItem(b, sp);
                item.PatientName = b.ChildId.HasValue && childMap.TryGetValue(b.ChildId.Value, out var ch)
                    ? ch.FullName : user!.FullName;
                return item;
            }).ToList();

            return ApiResponse<List<BookingListItemResponse>>.SuccessResponse(items, "تم جلب الحجوزات بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<List<BookingListItemResponse>>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<BookingDetailResponse>> GetBookingDetailAsync(Guid userId, Guid bookingId)
    {
        try
        {
            var (parent, user, error) = await ResolveParentAsync<BookingDetailResponse>(userId);
            if (error != null) return error;

            var booking = await _unitOfWork.Bookings.GetFirstOrDefaultAsync(
                b => b.Id == bookingId, "Attachments,Payment");
            if (booking == null || booking.ParentId != parent!.Id)
                return ApiResponse<BookingDetailResponse>.FailureResponse("لم يتم العثور على الحجز");

            await AutoCompleteEndedRemoteSessionsAsync(new[] { booking });

            var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.Id == booking.SpecialistId, "User");
            var patientName = await ResolvePatientNameAsync(booking, parent, user);
            var hasRated = await _unitOfWork.SessionRatings.ExistsAsync(r => r.BookingId == booking.Id);

            return ApiResponse<BookingDetailResponse>.SuccessResponse(
                MapToDetail(booking, specialist, patientName, hasRated), "تم جلب تفاصيل الحجز بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<BookingDetailResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<BookingDetailResponse>> CancelBookingAsync(Guid userId, Guid bookingId)
    {
        try
        {
            var (parent, user, error) = await ResolveParentAsync<BookingDetailResponse>(userId);
            if (error != null) return error;

            var booking = await _unitOfWork.Bookings.GetFirstOrDefaultAsync(
                b => b.Id == bookingId, "Attachments,Payment");
            if (booking == null || booking.ParentId != parent!.Id)
                return ApiResponse<BookingDetailResponse>.FailureResponse("لم يتم العثور على الحجز");

            if (booking.Status is BookingStatus.Cancelled or BookingStatus.Completed or BookingStatus.Rejected)
                return ApiResponse<BookingDetailResponse>.FailureResponse("لا يمكن إلغاء الحجز في الحالة الحالية");

            booking.Status = BookingStatus.Cancelled;
            booking.CancelledAt = DateTime.UtcNow;
            booking.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Bookings.UpdateAsync(booking);
            await _unitOfWork.SaveChangesAsync();

            var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.Id == booking.SpecialistId, "User");
            var patientName = await ResolvePatientNameAsync(booking, parent, user);

            return ApiResponse<BookingDetailResponse>.SuccessResponse(
                MapToDetail(booking, specialist, patientName), "تم إلغاء الحجز");
        }
        catch (Exception ex)
        {
            return ApiResponse<BookingDetailResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<List<ParentPaymentListItemResponse>>> GetMyPaymentsAsync(Guid userId)
    {
        try
        {
            var (parent, _, error) = await ResolveParentAsync<List<ParentPaymentListItemResponse>>(userId);
            if (error != null) return error;

            var payments = (await _unitOfWork.Payments.FindAsync(p => p.ParentId == parent!.Id))
                .OrderByDescending(p => p.CreatedAt)
                .ToList();
            if (payments.Count == 0)
                return ApiResponse<List<ParentPaymentListItemResponse>>.SuccessResponse(new List<ParentPaymentListItemResponse>(), "لا توجد معاملات مالية");

            var bookingIds = payments.Select(p => p.BookingId).ToHashSet();
            var bookings = (await _unitOfWork.Bookings.FindAsync(b => bookingIds.Contains(b.Id)))
                .ToDictionary(b => b.Id);
            var specialistIds = bookings.Values.Select(b => b.SpecialistId).ToHashSet();
            var specialists = (await _unitOfWork.Specialists.GetAllAsync(q => q.Include(s => s.User)))
                .Where(s => specialistIds.Contains(s.Id))
                .ToDictionary(s => s.Id);

            var items = payments.Select(p =>
            {
                bookings.TryGetValue(p.BookingId, out var b);
                Specialist? sp = b != null && specialists.TryGetValue(b.SpecialistId, out var s) ? s : null;
                return new ParentPaymentListItemResponse
                {
                    PaymentId = p.Id,
                    BookingId = p.BookingId,
                    DoctorName = sp?.User?.FullName ?? string.Empty,
                    ServiceTypeAr = b != null ? ConsultationLabels.ServiceTypeAr(b.ServiceType) : string.Empty,
                    Amount = p.Amount,
                    Method = ConsultationLabels.PaymentMethodKey(p.Method),
                    MethodAr = ConsultationLabels.PaymentMethodAr(p.Method),
                    Status = ConsultationLabels.PaymentStatusKey(p.Status),
                    StatusAr = ConsultationLabels.PaymentStatusAr(p.Status),
                    ReceiptImageUrl = p.ReceiptImageUrl,
                    AppointmentDate = b != null ? b.AppointmentDate.ToString("yyyy-MM-dd") : string.Empty,
                    CreatedAt = p.CreatedAt
                };
            }).ToList();

            return ApiResponse<List<ParentPaymentListItemResponse>>.SuccessResponse(items, "تم جلب المعاملات المالية بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<List<ParentPaymentListItemResponse>>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── جلسة الكشف اون لاين (Google Meet) ──────────────────────────────────────

    public async Task<ApiResponse<SessionStatusResponse>> GetSessionStatusAsync(Guid userId, Guid bookingId)
    {
        try
        {
            var (parent, _, error) = await ResolveParentAsync<SessionStatusResponse>(userId);
            if (error != null) return error;

            var booking = await _unitOfWork.Bookings.GetByIdAsync(bookingId);
            if (booking == null || booking.ParentId != parent!.Id)
                return ApiResponse<SessionStatusResponse>.FailureResponse("لم يتم العثور على الحجز");

            if (booking.ServiceType != BookingServiceType.RemoteConsultation)
                return ApiResponse<SessionStatusResponse>.FailureResponse("هذا الحجز ليس جلسة اون لاين");

            await AutoCompleteEndedRemoteSessionsAsync(new[] { booking });

            var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.Id == booking.SpecialistId, "User");

            var now = WorkingHoursHelper.EgyptNow();
            var startLocal = booking.AppointmentDate.Date + (booking.StartTime ?? TimeSpan.Zero);
            var endLocal = booking.EndTime.HasValue
                ? booking.AppointmentDate.Date + booking.EndTime.Value
                : startLocal.AddMinutes(booking.DurationMinutes ?? 30);
            var doctorStarted = booking.SessionStartedAt.HasValue && !string.IsNullOrEmpty(booking.MeetingUrl);
            var sessionEnded = now > endLocal;
            var canJoin = doctorStarted && !sessionEnded && booking.Status == BookingStatus.Confirmed;

            // حالة عرض حسب وقت الجلسة: مكتملة بعد انتهائها، متاحة عند بدء الطبيب، وإلا انتظار الموعد.
            string statusAr;
            if (booking.Status == BookingStatus.Confirmed && sessionEnded)
                statusAr = "جلسة مكتملة";
            else if (booking.Status == BookingStatus.Confirmed && doctorStarted)
                statusAr = "الطبيب متاح الان للبدء";
            else
                statusAr = ConsultationLabels.BookingStatusAr(booking.Status);

            var response = new SessionStatusResponse
            {
                BookingId = booking.Id,
                ServiceType = ConsultationLabels.ServiceTypeKey(booking.ServiceType),
                Status = ConsultationLabels.BookingStatusKey(booking.Status),
                StatusAr = statusAr,
                DoctorName = specialist?.User?.FullName ?? string.Empty,
                PhotoUrl = specialist?.PersonalPhotoUrl,
                Specialization = specialist?.Specialization ?? string.Empty,
                AppointmentDate = booking.AppointmentDate.ToString("yyyy-MM-dd"),
                StartTime = booking.StartTime.HasValue ? WorkingHoursHelper.Format(booking.StartTime.Value) : null,
                EndTime = booking.EndTime.HasValue ? WorkingHoursHelper.Format(booking.EndTime.Value) : null,
                ServerTimeEgypt = now,
                SecondsUntilStart = (long)Math.Round((startLocal - now).TotalSeconds),
                DoctorStarted = doctorStarted,
                CanJoin = canJoin,
                JoinUrl = canJoin ? booking.MeetingUrl : null
            };

            return ApiResponse<SessionStatusResponse>.SuccessResponse(response, "تم جلب حالة الجلسة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<SessionStatusResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── السجل الإكلينيكي (عرض فقط) ──────────────────────────────────────────────

    public async Task<ApiResponse<ParentPrescriptionResponse>> GetPrescriptionAsync(Guid userId, Guid bookingId)
    {
        try
        {
            var (booking, parent, error) = await ResolveBookingAsync<ParentPrescriptionResponse>(userId, bookingId);
            if (error != null) return error;

            await AutoCompleteEndedRemoteSessionsAsync(new[] { booking! });

            var response = new ParentPrescriptionResponse
            {
                Medicines = (await _unitOfWork.PrescriptionMedicines.FindAsync(m => m.BookingId == booking!.Id))
                    .OrderBy(m => m.CreatedAt)
                    .Select(m => new PrescriptionMedicineDto
                    {
                        Id = m.Id,
                        MedicineName = m.MedicineName,
                        Quantity = m.Quantity,
                        Timing = m.Timing,
                        CreatedAt = m.CreatedAt,
                        UpdatedAt = m.UpdatedAt
                    })
                    .ToList()
            };
            await PopulateClinicalCardHeaderAsync(response, booking!, parent!);

            return ApiResponse<ParentPrescriptionResponse>.SuccessResponse(response, "تم جلب الروشتة الطبية بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ParentPrescriptionResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<ParentDiagnosisResponse>> GetDiagnosisAsync(Guid userId, Guid bookingId)
    {
        try
        {
            var (booking, parent, error) = await ResolveBookingAsync<ParentDiagnosisResponse>(userId, bookingId);
            if (error != null) return error;

            await AutoCompleteEndedRemoteSessionsAsync(new[] { booking! });

            var diagnosis = await _unitOfWork.MedicalDiagnoses.GetFirstOrDefaultAsync(d => d.BookingId == booking!.Id);
            var response = new ParentDiagnosisResponse
            {
                HasDiagnosis = diagnosis != null,
                Diagnosis = diagnosis == null ? null : new MedicalDiagnosisDto
                {
                    Id = diagnosis.Id,
                    Description = diagnosis.Description,
                    CreatedAt = diagnosis.CreatedAt,
                    UpdatedAt = diagnosis.UpdatedAt
                }
            };
            await PopulateClinicalCardHeaderAsync(response, booking!, parent!);

            return ApiResponse<ParentDiagnosisResponse>.SuccessResponse(response, "تم جلب التشخيص الطبي بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<ParentDiagnosisResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    // ── تقييم الجلسة (المرحلة الثامنة) ──────────────────────────────────────────

    public async Task<ApiResponse<SessionRatingResponse>> GetSessionRatingAsync(Guid userId, Guid bookingId)
    {
        try
        {
            var (booking, parent, error) = await ResolveBookingAsync<SessionRatingResponse>(userId, bookingId);
            if (error != null) return error;

            await AutoCompleteEndedRemoteSessionsAsync(new[] { booking! });

            var rating = await _unitOfWork.SessionRatings.GetFirstOrDefaultAsync(r => r.BookingId == booking!.Id);
            return ApiResponse<SessionRatingResponse>.SuccessResponse(
                BuildRatingResponse(booking!, rating, parent!.StarsBalance), "تم جلب حالة تقييم الجلسة بنجاح");
        }
        catch (Exception ex)
        {
            return ApiResponse<SessionRatingResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    public async Task<ApiResponse<SessionRatingResponse>> SubmitSessionRatingAsync(Guid userId, Guid bookingId, SubmitSessionRatingRequest request)
    {
        try
        {
            var (booking, parent, error) = await ResolveBookingAsync<SessionRatingResponse>(userId, bookingId);
            if (error != null) return error;

            // ── التحقق من المدخلات ──
            if (request.Rating < 1 || request.Rating > 5)
                return ApiResponse<SessionRatingResponse>.FailureResponse("التقييم يجب أن يكون من 1 الى 5 نجوم");

            if (request.HadIssue && string.IsNullOrWhiteSpace(request.IssueDescription))
                return ApiResponse<SessionRatingResponse>.FailureResponse("يرجى كتابة وصف المشكلة التي واجهتها");

            // ── البوابة: لا يمكن التقييم إلا بعد اكتمال الجلسة ──
            await AutoCompleteEndedRemoteSessionsAsync(new[] { booking! });
            if (booking!.Status != BookingStatus.Completed)
                return ApiResponse<SessionRatingResponse>.FailureResponse("لا يمكن تقييم الجلسة قبل اكتمالها");

            // ── منع التقييم المكرر (وبالتالي تكرار منح النجوم) ──
            var existing = await _unitOfWork.SessionRatings.GetFirstOrDefaultAsync(r => r.BookingId == booking.Id);
            if (existing != null)
                return ApiResponse<SessionRatingResponse>.FailureResponse("لا يمكن تقييم الجلسة أكثر من مرة");

            var rating = new SessionRating
            {
                Id = Guid.NewGuid(),
                BookingId = booking.Id,
                ParentId = parent!.Id,
                Rating = request.Rating,
                WouldBookAgain = request.WouldBookAgain,
                HadIssue = request.HadIssue,
                IssueDescription = request.HadIssue ? request.IssueDescription!.Trim() : null,
                StarsAwarded = SessionRatingStarsReward,
                CreatedAt = DateTime.UtcNow
            };

            // ── منح نجوم المكافأة لرصيد ولي الأمر (مرة واحدة) ──
            parent.StarsBalance += SessionRatingStarsReward;
            parent.UpdatedAt = DateTime.UtcNow;

            await _unitOfWork.SessionRatings.AddAsync(rating);
            await _unitOfWork.Parents.UpdateAsync(parent);
            await _unitOfWork.SaveChangesAsync();

            return ApiResponse<SessionRatingResponse>.SuccessResponse(
                BuildRatingResponse(booking, rating, parent.StarsBalance),
                $"تم اضافة {SessionRatingStarsReward} نجمة الى رصيدك");
        }
        catch (Exception ex)
        {
            return ApiResponse<SessionRatingResponse>.FailureResponse("حدث خطأ في الخادم", new List<string> { ex.Message });
        }
    }

    /// <summary>يبني استجابة حالة تقييم الجلسة (مع/بدون تقييم موجود).</summary>
    private static SessionRatingResponse BuildRatingResponse(Booking booking, SessionRating? rating, int starsBalance) => new()
    {
        BookingId = booking.Id,
        HasRated = rating != null,
        CanRate = booking.Status == BookingStatus.Completed && rating == null,
        Rating = rating?.Rating,
        WouldBookAgain = rating?.WouldBookAgain,
        HadIssue = rating?.HadIssue,
        IssueDescription = rating?.IssueDescription,
        RatedAt = rating?.CreatedAt,
        StarsAwarded = rating?.StarsAwarded ?? SessionRatingStarsReward,
        NewStarsBalance = starsBalance
    };

    /// <summary>يملأ ترويسة بطاقة السجل الإكلينيكي (الطبيب + المريض + التاريخ) المشتركة بين الروشتة والتشخيص.</summary>
    private async Task PopulateClinicalCardHeaderAsync(ParentClinicalCardHeader header, Booking booking, Parent parent)
    {
        var specialist = await _unitOfWork.Specialists.GetFirstOrDefaultAsync(s => s.Id == booking.SpecialistId, "User");

        header.BookingId = booking.Id;
        header.DoctorName = specialist?.User?.FullName ?? string.Empty;
        header.Specialization = specialist?.Specialization ?? string.Empty;
        header.DoctorPhotoUrl = specialist?.PersonalPhotoUrl;
        header.AppointmentDate = booking.AppointmentDate.ToString("yyyy-MM-dd");
        header.IsCompleted = booking.Status == BookingStatus.Completed;

        if (booking.ChildId.HasValue)
        {
            var child = await _unitOfWork.Children.GetByIdAsync(booking.ChildId.Value);
            header.PatientName = child?.FullName ?? string.Empty;
            header.PatientAge = child?.Age;
        }
        else
        {
            var user = await _unitOfWork.Users.GetByIdAsync(parent.UserId);
            header.PatientName = user?.FullName ?? string.Empty;
            header.PatientAge = AgeFromDateOfBirth(parent.DateOfBirth);
        }
    }

    /// <summary>يحسب السن بالسنوات من تاريخ الميلاد (null إذا كان التاريخ غير محدد).</summary>
    private static int? AgeFromDateOfBirth(DateTime dateOfBirth)
    {
        if (dateOfBirth == default) return null;
        var today = WorkingHoursHelper.EgyptNow().Date;
        var age = today.Year - dateOfBirth.Year;
        if (dateOfBirth.Date > today.AddYears(-age)) age--;
        return age < 0 ? null : age;
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    /// <summary>
    /// يُكمِل تلقائياً جلسات الكشف اون لاين المؤكدة التي انتهى وقتها (الحالة → مكتملة) ويحفظ التغيير،
    /// كي تعرض جميع نقاط النهاية حالة موحّدة. يُرجع عدد الحجوزات التي تم تحديثها.
    /// </summary>
    private async Task<int> AutoCompleteEndedRemoteSessionsAsync(IEnumerable<Booking> bookings)
    {
        var now = WorkingHoursHelper.EgyptNow();
        var changed = 0;

        foreach (var b in bookings)
        {
            if (b.ServiceType != BookingServiceType.RemoteConsultation) continue;
            if (b.Status != BookingStatus.Confirmed) continue;
            if (!b.StartTime.HasValue) continue;

            var startLocal = b.AppointmentDate.Date + b.StartTime.Value;
            var endLocal = b.EndTime.HasValue
                ? b.AppointmentDate.Date + b.EndTime.Value
                : startLocal.AddMinutes(b.DurationMinutes ?? 30);

            if (now <= endLocal) continue;

            b.Status = BookingStatus.Completed;
            b.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Bookings.UpdateAsync(b);
            changed++;
        }

        if (changed > 0) await _unitOfWork.SaveChangesAsync();
        return changed;
    }

    private async Task<(Parent? parent, User? user, ApiResponse<T>? error)> ResolveParentAsync<T>(Guid userId)
    {
        var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == userId);
        if (parent == null)
            return (null, null, ApiResponse<T>.FailureResponse("لم يتم العثور على بيانات ولي الأمر"));
        var user = await _unitOfWork.Users.GetByIdAsync(userId);
        if (user == null)
            return (null, null, ApiResponse<T>.FailureResponse("لم يتم العثور على بيانات المستخدم"));
        return (parent, user, null);
    }

    private async Task<(Booking? booking, Parent? parent, ApiResponse<T>? error)> ResolveBookingAsync<T>(Guid userId, Guid bookingId)
    {
        var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(p => p.UserId == userId);
        if (parent == null)
            return (null, null, ApiResponse<T>.FailureResponse("لم يتم العثور على بيانات ولي الأمر"));

        var booking = await _unitOfWork.Bookings.GetByIdAsync(bookingId);
        if (booking == null)
            return (null, null, ApiResponse<T>.FailureResponse("لم يتم العثور على الحجز"));
        if (booking.ParentId != parent.Id)
            return (null, null, ApiResponse<T>.FailureResponse("غير مصرح - هذا الحجز لا يخصك"));

        return (booking, parent, null);
    }

    private async Task<Clinic?> GetApprovedClinicAsync(Guid specialistId) =>
        (await _unitOfWork.Clinics.FindAsync(c => c.SpecialistId == specialistId && c.Status == ClinicStatus.Approved))
            .OrderBy(c => c.CreatedAt).FirstOrDefault();

    private async Task<RemoteConsultation?> GetApprovedRemoteAsync(Guid specialistId) =>
        (await _unitOfWork.RemoteConsultations.FindAsync(r => r.SpecialistId == specialistId && r.Status == RemoteConsultationStatus.Approved))
            .OrderBy(r => r.CreatedAt).FirstOrDefault();

    private async Task<HashSet<TimeSpan>> GetBookedRemoteStartTimesAsync(Guid specialistId, DateTime date)
    {
        var active = new[] { BookingStatus.PendingPayment, BookingStatus.PendingReview, BookingStatus.Confirmed };
        var bookings = await _unitOfWork.Bookings.FindAsync(b =>
            b.SpecialistId == specialistId &&
            b.ServiceType == BookingServiceType.RemoteConsultation &&
            b.AppointmentDate == date &&
            active.Contains(b.Status));
        return bookings.Where(b => b.StartTime.HasValue).Select(b => b.StartTime!.Value).ToHashSet();
    }

    private async Task<(Dictionary<Guid, Specialist> specialists, Dictionary<Guid, Child> children)> LoadBookingLookupsAsync(List<Booking> bookings)
    {
        var specialistIds = bookings.Select(b => b.SpecialistId).ToHashSet();
        var childIds = bookings.Where(b => b.ChildId.HasValue).Select(b => b.ChildId!.Value).ToHashSet();

        var specialists = (await _unitOfWork.Specialists.GetAllAsync(q => q.Include(s => s.User)))
            .Where(s => specialistIds.Contains(s.Id))
            .ToDictionary(s => s.Id);

        var children = childIds.Count == 0
            ? new Dictionary<Guid, Child>()
            : (await _unitOfWork.Children.FindAsync(c => childIds.Contains(c.Id))).ToDictionary(c => c.Id);

        return (specialists, children);
    }

    private async Task<string> ResolvePatientNameAsync(Booking booking, Parent parent, User? user = null)
    {
        if (!booking.ChildId.HasValue)
        {
            user ??= await _unitOfWork.Users.GetByIdAsync(parent.UserId);
            return user?.FullName ?? string.Empty;
        }
        var child = await _unitOfWork.Children.GetByIdAsync(booking.ChildId.Value);
        return child?.FullName ?? string.Empty;
    }

    private async Task<ApiResponse<List<AttachmentDto>>> GetAttachmentsResponseAsync(Guid bookingId, string message)
    {
        var attachments = (await _unitOfWork.BookingAttachments.FindAsync(a => a.BookingId == bookingId))
            .OrderBy(a => a.CreatedAt)
            .Select(a => new AttachmentDto { Id = a.Id, ImageUrl = a.ImageUrl })
            .ToList();
        return ApiResponse<List<AttachmentDto>>.SuccessResponse(attachments, message);
    }

    private static bool TryParseServiceType(string serviceType, out BookingServiceType type)
    {
        switch ((serviceType ?? string.Empty).Trim().ToLowerInvariant())
        {
            case "clinic": type = BookingServiceType.Clinic; return true;
            case "remote": type = BookingServiceType.RemoteConsultation; return true;
            default: type = BookingServiceType.Clinic; return false;
        }
    }

    private static BookingSummaryResponse BuildSummary(Booking b, Specialist? specialist, string patientName) => new()
    {
        BookingId = b.Id,
        Status = ConsultationLabels.BookingStatusKey(b.Status),
        StatusAr = ConsultationLabels.BookingStatusAr(b.Status),
        ServiceType = ConsultationLabels.ServiceTypeKey(b.ServiceType),
        ServiceTypeAr = ConsultationLabels.ServiceTypeAr(b.ServiceType),
        DoctorName = specialist?.User?.FullName ?? string.Empty,
        PhotoUrl = specialist?.PersonalPhotoUrl,
        Specialization = specialist?.Specialization ?? string.Empty,
        AppointmentDate = b.AppointmentDate.ToString("yyyy-MM-dd"),
        StartTime = b.StartTime.HasValue ? WorkingHoursHelper.Format(b.StartTime.Value) : null,
        EndTime = b.EndTime.HasValue ? WorkingHoursHelper.Format(b.EndTime.Value) : null,
        DurationMinutes = b.DurationMinutes,
        Amount = b.Price,
        PatientName = patientName
    };

    private static BookingListItemResponse MapToListItem(Booking b, Specialist? specialist) => new()
    {
        BookingId = b.Id,
        Status = ConsultationLabels.BookingStatusKey(b.Status),
        StatusAr = ConsultationLabels.BookingStatusAr(b.Status),
        ServiceType = ConsultationLabels.ServiceTypeKey(b.ServiceType),
        ServiceTypeAr = ConsultationLabels.ServiceTypeAr(b.ServiceType),
        SpecialistId = b.SpecialistId,
        DoctorName = specialist?.User?.FullName ?? string.Empty,
        PhotoUrl = specialist?.PersonalPhotoUrl,
        Specialization = specialist?.Specialization ?? string.Empty,
        AppointmentDate = b.AppointmentDate.ToString("yyyy-MM-dd"),
        StartTime = b.StartTime.HasValue ? WorkingHoursHelper.Format(b.StartTime.Value) : null,
        EndTime = b.EndTime.HasValue ? WorkingHoursHelper.Format(b.EndTime.Value) : null,
        DurationMinutes = b.DurationMinutes,
        Price = b.Price,
        CreatedAt = b.CreatedAt,
        CanCancel = b.Status is BookingStatus.PendingPayment or BookingStatus.PendingReview or BookingStatus.Confirmed
    };

    private static BookingDetailResponse MapToDetail(Booking b, Specialist? specialist, string patientName, bool hasRated = false)
    {
        var detail = new BookingDetailResponse
        {
            HasRated = hasRated,
            CanRate = b.Status == BookingStatus.Completed && !hasRated,
            BookingId = b.Id,
            Status = ConsultationLabels.BookingStatusKey(b.Status),
            StatusAr = ConsultationLabels.BookingStatusAr(b.Status),
            RejectionReason = b.RejectionReason,
            ServiceType = ConsultationLabels.ServiceTypeKey(b.ServiceType),
            ServiceTypeAr = ConsultationLabels.ServiceTypeAr(b.ServiceType),
            SpecialistId = b.SpecialistId,
            DoctorName = specialist?.User?.FullName ?? string.Empty,
            PhotoUrl = specialist?.PersonalPhotoUrl,
            Specialization = specialist?.Specialization ?? string.Empty,
            AppointmentDate = b.AppointmentDate.ToString("yyyy-MM-dd"),
            StartTime = b.StartTime.HasValue ? WorkingHoursHelper.Format(b.StartTime.Value) : null,
            EndTime = b.EndTime.HasValue ? WorkingHoursHelper.Format(b.EndTime.Value) : null,
            DurationMinutes = b.DurationMinutes,
            Price = b.Price,
            PatientName = patientName,
            ChildId = b.ChildId,
            ComplaintDescription = b.ComplaintDescription,
            ShareMedicalFile = b.ShareMedicalFile,
            MedicalFileUrl = b.MedicalFileUrl,
            CreatedAt = b.CreatedAt,
            CanCancel = b.Status is BookingStatus.PendingPayment or BookingStatus.PendingReview or BookingStatus.Confirmed,
            Attachments = (b.Attachments ?? new List<BookingAttachment>())
                .OrderBy(a => a.CreatedAt)
                .Select(a => new AttachmentDto { Id = a.Id, ImageUrl = a.ImageUrl })
                .ToList()
        };

        if (b.Payment != null)
        {
            detail.PaymentStatus = ConsultationLabels.PaymentStatusKey(b.Payment.Status);
            detail.PaymentStatusAr = ConsultationLabels.PaymentStatusAr(b.Payment.Status);
            detail.PaymentMethod = ConsultationLabels.PaymentMethodAr(b.Payment.Method);
            detail.ReceiptImageUrl = b.Payment.ReceiptImageUrl;
        }

        return detail;
    }
}
