namespace Ajial.Application.Helpers;

/// <summary>
/// مساعدات تنسيق نصوص الملف الطبي الموحد (تواريخ عربية، الأعمار، رقم الملف الصحي).
/// </summary>
public static class MedicalFileLabels
{
    private static readonly string[] ArabicMonths =
    {
        "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
        "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
    };

    /// <summary>"12 يناير 2023".</summary>
    public static string ArabicDate(DateTime date) =>
        $"{date.Day} {ArabicMonths[date.Month - 1]} {date.Year}";

    /// <summary>"3 سنوات و 4 أشهر" — صياغة عربية صحيحة للعمر.</summary>
    public static string AgeLabel(int years, int months)
    {
        string YearsPart(int y) => y switch
        {
            0 => "",
            1 => "سنة",
            2 => "سنتان",
            >= 3 and <= 10 => $"{y} سنوات",
            _ => $"{y} سنة"
        };

        string MonthsPart(int m) => m switch
        {
            0 => "",
            1 => "شهر",
            2 => "شهران",
            >= 3 and <= 10 => $"{m} أشهر",
            _ => $"{m} شهراً"
        };

        var y = YearsPart(years);
        var mo = MonthsPart(months);

        if (!string.IsNullOrEmpty(y) && !string.IsNullOrEmpty(mo)) return $"{y} و {mo}";
        if (!string.IsNullOrEmpty(y)) return y;
        if (!string.IsNullOrEmpty(mo)) return mo;
        return "أقل من شهر";
    }

    /// <summary>العمر المستهدف للتطعيم من عدد الشهور: "عند الولادة" / "شهران" / "سنة ونصف" ...</summary>
    public static string TargetAgeLabel(int ageInMonths) => ageInMonths switch
    {
        0 => "عند الولادة",
        1 => "شهر",
        2 => "شهران",
        18 => "18 شهراً",
        >= 3 and <= 10 => $"{ageInMonths} أشهر",
        < 12 => $"{ageInMonths} شهراً",
        _ when ageInMonths % 12 == 0 => AgeLabel(ageInMonths / 12, 0),
        _ => AgeLabel(ageInMonths / 12, ageInMonths % 12)
    };

    /// <summary>
    /// رقم ملف صحي ثابت لكل طفل مشتق من معرّفه (GUID) — لا يتغيّر عند إعادة التوليد.
    /// مثال: AJ-983422.
    /// </summary>
    public static string HealthFileNumber(Guid childId)
    {
        var bytes = childId.ToByteArray();
        // استخدام أول 4 بايت لإنتاج رقم ثابت من 6 خانات
        uint seed = BitConverter.ToUInt32(bytes, 0);
        uint sixDigits = seed % 1_000_000u;
        return $"AJ-{sixDigits:D6}";
    }

    /// <summary>
    /// يعزل نصاً لاتينياً اتجاهياً (LTR) داخل سياق عربي (RTL) لتفادي قلب الرموز الضعيفة
    /// مثل "+" في "O+". يستخدم علامتي العزل LRI…PDI من يونيكود.
    /// </summary>
    public static string LatinIsolate(string value) => "⁦" + value + "⁩";

}
