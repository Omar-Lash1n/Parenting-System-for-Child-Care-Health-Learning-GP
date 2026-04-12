namespace Ajial.Domain.Entities;

/// <summary>
/// مراكز التطعيم والوحدات الصحية في مصر
/// Vaccination places and health units in Egypt — master reference data
/// </summary>
public class HealthUnit
{
    public int Id { get; set; }

    // ── Names ──────────────────────────────────────────────────
    /// <summary>اسم الوحدة بالعربي — e.g. "وحدة صحة الأسرة - شارع المستشفى"</summary>
    public string NameAr { get; set; } = string.Empty;

    /// <summary>اسم الوحدة بالإنجليزي — e.g. "Family Health Unit - Hospital St"</summary>
    public string NameEn { get; set; } = string.Empty;

    // ── Type ───────────────────────────────────────────────────
    /// <summary>نوع المكان: وحدة صحية / مستشفى / مركز تطعيم</summary>
    public HealthUnitType Type { get; set; }

    // ── Address ────────────────────────────────────────────────
    /// <summary>العنوان بالعربي</summary>
    public string AddressAr { get; set; } = string.Empty;

    /// <summary>العنوان بالإنجليزي (optional)</summary>
    public string? AddressEn { get; set; }

    // ── Location (FK to City / Governorate) ────────────────────
    public int CityId { get; set; }
    public City City { get; set; } = null!;

    // ── Geolocation ────────────────────────────────────────────
    /// <summary>خط العرض</summary>
    public double Latitude { get; set; }

    /// <summary>خط الطول</summary>
    public double Longitude { get; set; }

    // ── Contact ────────────────────────────────────────────────
    public string? Phone { get; set; }

    // ── Metadata ───────────────────────────────────────────────
    /// <summary>ملاحظات — e.g. working hours, extra info</summary>
    public string? Notes { get; set; }

    /// <summary>مصدر البيانات — where this record came from</summary>
    public string? DataSource { get; set; }

    /// <summary>هل تم التحقق من البيانات؟</summary>
    public bool IsVerified { get; set; } = false;

    // ── Status ─────────────────────────────────────────────────
    public bool IsActive { get; set; } = true;

    // ── Audit ──────────────────────────────────────────────────
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
