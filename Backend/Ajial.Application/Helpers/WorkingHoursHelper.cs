using System.Globalization;
using System.Text.Json;

namespace Ajial.Application.Helpers;

/// <summary>
/// أدوات قراءة مواعيد عمل الطبيب (WorkingHoursJson) وتوليد المواعيد المتاحة.
///
/// تنسيق WorkingHoursJson (يُخزّنه جانب الطبيب):
///   ثابت:  {"type":"fixed","from":"08:00","to":"16:00"}            ← يسري على كل الأيام
///   مخصص:  {"type":"specific","periods":[{"day":"الثلاثاء","from":"17:00","to":"21:00"}, ...]}
///
/// أسماء الأيام تطابق تماماً ما يرسله جانب الطبيب: السبت/الاحد/الاثنين/الثلاثاء/الاربعاء/الخميس/الجمعة.
/// محلّل الوقت متسامح: يقبل الصيغة المعيارية "HH:mm" وكذلك الأرقام العربية و ص/م و AM/PM (للبيانات القديمة).
/// </summary>
public static class WorkingHoursHelper
{
    /// <summary>التوقيت المحلي لمصر (UTC+2). يُستخدم لمقارنة المواعيد المستقبلية.</summary>
    public static DateTime EgyptNow() => DateTime.UtcNow.AddHours(2);

    private static readonly string[] ArabicWeekdays =
    {
        "الاحد",    // Sunday    = 0
        "الاثنين",  // Monday    = 1
        "الثلاثاء", // Tuesday   = 2
        "الاربعاء", // Wednesday = 3
        "الخميس",   // Thursday  = 4
        "الجمعة",   // Friday    = 5
        "السبت"     // Saturday  = 6
    };

    public static string ArabicWeekday(DateTime date) => ArabicWeekdays[(int)date.DayOfWeek];

    /// <summary>فترات العمل (from,to) ليوم محدد بناءً على WorkingHoursJson.</summary>
    public static List<(TimeSpan From, TimeSpan To)> GetPeriodsForDate(string? workingHoursJson, DateTime date)
    {
        var result = new List<(TimeSpan, TimeSpan)>();
        if (string.IsNullOrWhiteSpace(workingHoursJson)) return result;

        JsonDocument doc;
        try { doc = JsonDocument.Parse(workingHoursJson); }
        catch { return result; }

        using (doc)
        {
            var root = doc.RootElement;
            if (root.ValueKind != JsonValueKind.Object) return result;

            var type = root.TryGetProperty("type", out var t) ? t.GetString() : null;

            if (type == "fixed")
            {
                var from = ParseTime(GetString(root, "from"));
                var to = ParseTime(GetString(root, "to"));
                if (from.HasValue && to.HasValue && to > from)
                    result.Add((from.Value, to.Value));
            }
            else if (type == "specific" && root.TryGetProperty("periods", out var periods) && periods.ValueKind == JsonValueKind.Array)
            {
                var dayName = ArabicWeekday(date);
                foreach (var p in periods.EnumerateArray())
                {
                    if (GetString(p, "day") != dayName) continue;
                    var from = ParseTime(GetString(p, "from"));
                    var to = ParseTime(GetString(p, "to"));
                    if (from.HasValue && to.HasValue && to > from)
                        result.Add((from.Value, to.Value));
                }
            }
        }

        return result.OrderBy(r => r.Item1).ToList();
    }

    /// <summary>
    /// توليد مواعيد الجلسات اون لاين ليوم محدد.
    /// خطوة الموعد = مدة الجلسة + فترة الانتظار بين الجلسات.
    /// </summary>
    public static List<(TimeSpan Start, TimeSpan End)> GenerateRemoteSlots(
        string? workingHoursJson, DateTime date, int durationMinutes, int waitingMinutes)
    {
        var slots = new List<(TimeSpan, TimeSpan)>();
        if (durationMinutes <= 0) return slots;

        var duration = TimeSpan.FromMinutes(durationMinutes);
        var stride = TimeSpan.FromMinutes(durationMinutes + Math.Max(0, waitingMinutes));

        foreach (var (from, to) in GetPeriodsForDate(workingHoursJson, date))
        {
            var start = from;
            while (start + duration <= to)
            {
                slots.Add((start, start + duration));
                start += stride;
            }
        }

        return slots;
    }

    /// <summary>نص مواعيد العمل ليوم محدد (مثال: "من 05:00 الى 09:00").</summary>
    public static string BuildWorkingHoursText(List<(TimeSpan From, TimeSpan To)> periods)
    {
        if (periods.Count == 0) return string.Empty;
        return string.Join("، ", periods.Select(p => $"من {Format(p.From)} الى {Format(p.To)}"));
    }

    public static string Format(TimeSpan t) => $"{t.Hours:D2}:{t.Minutes:D2}";

    // ── Helpers ──────────────────────────────────────────────────────────────

    private static string GetString(JsonElement el, string prop) =>
        el.TryGetProperty(prop, out var v) && v.ValueKind == JsonValueKind.String ? (v.GetString() ?? string.Empty) : string.Empty;

    /// <summary>
    /// محلّل وقت متسامح: "19:45" أو "7:45" أو "٧:٤٥ م" أو "7:45 PM".
    /// </summary>
    public static TimeSpan? ParseTime(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;

        var s = raw.Trim();

        // Normalize Arabic-Indic & Persian digits → ASCII
        var sb = new System.Text.StringBuilder(s.Length);
        foreach (var ch in s)
        {
            if (ch >= '٠' && ch <= '٩') sb.Append((char)('0' + (ch - '٠')));      // Arabic-Indic
            else if (ch >= '۰' && ch <= '۹') sb.Append((char)('0' + (ch - '۰'))); // Persian
            else sb.Append(ch);
        }
        s = sb.ToString();

        // Detect meridiem
        bool isPm = s.Contains('م') || s.IndexOf("PM", StringComparison.OrdinalIgnoreCase) >= 0;
        bool isAm = s.Contains('ص') || s.IndexOf("AM", StringComparison.OrdinalIgnoreCase) >= 0;

        // Strip everything except digits and ':'
        var cleaned = new System.Text.StringBuilder(s.Length);
        foreach (var ch in s)
            if (char.IsDigit(ch) || ch == ':') cleaned.Append(ch);
        var core = cleaned.ToString();
        if (core.Length == 0) return null;

        int hour, minute = 0;
        var parts = core.Split(':');
        if (!int.TryParse(parts[0], NumberStyles.Integer, CultureInfo.InvariantCulture, out hour)) return null;
        if (parts.Length > 1 && parts[1].Length > 0 &&
            !int.TryParse(parts[1], NumberStyles.Integer, CultureInfo.InvariantCulture, out minute)) return null;

        if (isPm && hour < 12) hour += 12;
        if (isAm && hour == 12) hour = 0;

        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
        return new TimeSpan(hour, minute, 0);
    }
}
