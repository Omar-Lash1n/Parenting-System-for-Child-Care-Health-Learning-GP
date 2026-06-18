namespace Ajial.Domain.Entities;

/// <summary>
/// إعداد دفع قابل للتعديل من لوحة الأدمن (مثل أرقام المحافظ) — مخزّن كمفتاح/قيمة.
/// Admin-configurable payment setting (e.g. wallet numbers) stored as key/value.
/// </summary>
public class PaymentSetting
{
    public int Id { get; set; }
    public string Key { get; set; } = string.Empty;   // e.g. "VodafoneCashNumber", "InstaPayNumber"
    public string Value { get; set; } = string.Empty;
    public DateTime? UpdatedAt { get; set; }
    public Guid? UpdatedByUserId { get; set; }
}
