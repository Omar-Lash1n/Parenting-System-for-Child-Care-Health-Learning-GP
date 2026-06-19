namespace Ajial.Application.DTOs.Consultation;

// ============================================================
// لوحة الأدمن — مراجعة المدفوعات + إعدادات أرقام الدفع
// ============================================================

public class AdminPaymentListResponse
{
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public List<AdminPaymentListItemDto> Items { get; set; } = new();
}

public class AdminPaymentListItemDto
{
    public Guid PaymentId { get; set; }
    public Guid BookingId { get; set; }
    public string ParentName { get; set; } = string.Empty;
    public string DoctorName { get; set; } = string.Empty;
    public string ServiceTypeAr { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Method { get; set; } = string.Empty;
    public string MethodAr { get; set; } = string.Empty;
    public string ReceiptImageUrl { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class AdminPaymentDetailResponse
{
    public Guid PaymentId { get; set; }
    public Guid BookingId { get; set; }

    public string ParentName { get; set; } = string.Empty;
    public string PatientName { get; set; } = string.Empty;
    public string DoctorName { get; set; } = string.Empty;
    public string Specialization { get; set; } = string.Empty;

    public string ServiceTypeAr { get; set; } = string.Empty;
    public string AppointmentDate { get; set; } = string.Empty;
    public string? StartTime { get; set; }
    public string? EndTime { get; set; }

    public decimal Amount { get; set; }
    public string Method { get; set; } = string.Empty;
    public string MethodAr { get; set; } = string.Empty;
    public string ReceiptImageUrl { get; set; } = string.Empty;

    public string Status { get; set; } = string.Empty;
    public string StatusAr { get; set; } = string.Empty;
    public string? RejectionReason { get; set; }

    public string BookingStatus { get; set; } = string.Empty;
    public string BookingStatusAr { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
}

public class PaymentStatusChangeResponse
{
    public Guid PaymentId { get; set; }
    public Guid BookingId { get; set; }
    public string PaymentStatus { get; set; } = string.Empty;
    public string PaymentStatusAr { get; set; } = string.Empty;
    public string BookingStatus { get; set; } = string.Empty;
    public string BookingStatusAr { get; set; } = string.Empty;
}

public class RejectPaymentRequest
{
    public string Reason { get; set; } = string.Empty;
}

public class PaymentSettingsResponse
{
    public string VodafoneCashNumber { get; set; } = string.Empty;
    public string InstaPayNumber { get; set; } = string.Empty;
}

public class UpdatePaymentSettingsRequest
{
    public string? VodafoneCashNumber { get; set; }
    public string? InstaPayNumber { get; set; }
}
