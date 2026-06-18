using System.Reflection;
using Ajial.Application.DTOs.MedicalFile;
using Ajial.Application.Interfaces;
using QuestPDF.Drawing;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace Ajial.Infrastructure.Services;

/// <summary>
/// مولّد الملف الطبي الموحد للطفل باستخدام QuestPDF — صفحتان A4 من اليمين لليسار
/// مطابقتان لقالب أجيال (الثيم العنابي، البطاقات، الجداول، السجل المرضي).
/// </summary>
public class QuestPdfMedicalFileGenerator : IMedicalFilePdfGenerator
{
    // ── ألوان القالب ──
    private const string Maroon = "#7a0c18";   // العنابي الأساسي (الترويسة، عناوين الأقسام، خلايا الـ label، رؤوس الجداول)
    private const string MaroonAccent = "#9f1724"; // شريط عنوان القسم + الشريط العلوي
    private const string MaroonLabel = "#8a1a26";  // عناوين بطاقات الملخص
    private const string ThBorder = "#8e1a27";
    private const string TextDark = "#1f2937";
    private const string TextBody = "#333b45";
    private const string Subtitle = "#5f6670";
    private const string MetaText = "#6b7280";
    private const string CardBg = "#fff8f8";
    private const string CardBorder = "#f2c6cd";
    private const string SectionBorder = "#eee1e3";
    private const string SectionTitleBg = "#fff4f5";
    private const string TdBorder = "#ead4d8";
    private const string RowAlt = "#fffafa";
    private const string OkBg = "#f2fff5";
    private const string OkText = "#207043";
    private const string OkBorder = "#bfe5ca";
    private const string PendingBg = "#fbe7ea";
    private const string PendingText = "#7a0c18";
    private const string PendingBorder = "#e9b0b8";
    private const string FooterText = "#9a8e91";
    private const string FooterBorder = "#f0d9dd";
    private const string DashBorder = "#e9c4ca";
    private const string SecurityBorder = "#ead3d7";
    private const string SecurityBg = "#fffafa";
    private const string QrBorder = "#c9a3a9";
    private const string QrText = "#a9959a";

    private const string ArabicFont = "Noto Sans Arabic";
    private const string KufiFont = "Noto Kufi Arabic";

    private static readonly byte[]? LogoBytes = LoadLogo();

    static QuestPdfMedicalFileGenerator()
    {
        QuestPDF.Settings.License = LicenseType.Community;
        RegisterEmbeddedFonts();
    }

    private static byte[]? LoadLogo()
    {
        var asm = Assembly.GetExecutingAssembly();
        var name = asm.GetManifestResourceNames()
            .FirstOrDefault(n => n.EndsWith("ajial-logo.png", StringComparison.OrdinalIgnoreCase));
        if (name == null) return null;
        using var stream = asm.GetManifestResourceStream(name);
        if (stream == null) return null;
        using var ms = new MemoryStream();
        stream.CopyTo(ms);
        return ms.ToArray();
    }

    private static void RegisterEmbeddedFonts()
    {
        var asm = Assembly.GetExecutingAssembly();
        foreach (var name in asm.GetManifestResourceNames())
        {
            if (!name.EndsWith(".ttf", StringComparison.OrdinalIgnoreCase)) continue;
            using var stream = asm.GetManifestResourceStream(name);
            if (stream != null) FontManager.RegisterFont(stream);
        }
    }

    public byte[] Generate(MedicalFileData data)
    {
        return Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.MarginHorizontal(8, Unit.Millimetre);
                page.MarginVertical(7, Unit.Millimetre);
                page.DefaultTextStyle(x => x.FontFamily(ArabicFont).FontSize(9.2f).FontColor(TextBody).LineHeight(1.35f));
                page.ContentFromRightToLeft();

                page.Header().Element(c => Header(c, data));
                page.Content().Element(c => Content(c, data));
                page.Footer().Element(Footer);
            });
        }).GeneratePdf();
    }

    // ── الترويسة (تتكرّر في الصفحتين) ──
    private static void Header(IContainer container, MedicalFileData data)
    {
        container.Column(col =>
        {
            // الشريط العلوي العنابي
            col.Item().Height(5).Background(MaroonAccent);

            col.Item().PaddingTop(8).PaddingBottom(6).Row(row =>
            {
                // (RTL) أول عنصر = أقصى اليمين: بيانات الملف
                row.ConstantItem(150).Column(meta =>
                {
                    meta.Item().Text(t =>
                    {
                        t.Span("تاريخ آخر تحديث: ").Bold().FontColor(Maroon).FontSize(8.4f);
                        t.Span(data.LastUpdatedLabel).FontColor(MetaText).FontSize(8.4f);
                    });
                    meta.Item().Text(t =>
                    {
                        t.Span("رقم الملف الصحي: ").Bold().FontColor(Maroon).FontSize(8.4f);
                        t.Span(data.FileNumber).FontColor(MetaText).FontSize(8.4f);
                    });
                });

                // الوسط: العنوان الرئيسي
                row.RelativeItem().AlignCenter().Column(brand =>
                {
                    brand.Item().AlignCenter().Text("الملف الطبي الموحد للطفل")
                        .FontFamily(KufiFont).Bold().FontSize(18).FontColor(Maroon);
                    brand.Item().AlignCenter().Text("Medical Passport - تقرير أجيال الطبي")
                        .FontSize(9.5f).SemiBold().FontColor(Subtitle);
                });

                // (RTL) آخر عنصر = أقصى اليسار: شعار أجيال (أو علامة نصية احتياطية)
                if (LogoBytes != null)
                    row.ConstantItem(150).AlignLeft().AlignMiddle()
                        .Height(52).Image(LogoBytes).FitHeight();
                else
                    row.ConstantItem(150).AlignLeft().AlignMiddle()
                        .Text("أجيال").FontFamily(KufiFont).Bold().FontSize(22).FontColor(Maroon);
            });

            col.Item().Height(2).Background(CardBorder);
        });
    }

    private static void Footer(IContainer container)
    {
        container.PaddingTop(4).BorderTop(1).BorderColor(FooterBorder).Row(row =>
        {
            // (RTL) أول عنصر يمين
            row.RelativeItem().Text("تطبيق أجيال للرعاية الطبية").FontSize(8.5f).FontColor(FooterText);
            row.RelativeItem().AlignLeft().Text(t =>
            {
                t.DefaultTextStyle(s => s.FontSize(8.5f).FontColor(FooterText));
                t.Span("Page ");
                t.CurrentPageNumber();
                t.Span(" / ");
                t.TotalPages();
            });
        });
    }

    // ── المحتوى ──
    private static void Content(IContainer container, MedicalFileData data)
    {
        container.PaddingTop(8).Column(col =>
        {
            // ===== الصفحة الأولى =====
            SummaryRow(col, data);
            IdentitySection(col, data);
            GrowthSection(col, data);
            VaccineSection(col, "سجل التطعيمات والتحصينات", "(Vaccination Log)", data.MainVaccines, isOptional: false);

            col.Item().PageBreak();

            // ===== الصفحة الثانية =====
            VaccineSection(col, "التطعيمات الإضافية / الاختيارية", "(Optional Vaccines)", data.OptionalVaccines, isOptional: true);
            MedicalHistorySection(col, data);
            SecurityNote(col);
        });
    }

    // بطاقات الملخص الأربع
    private static void SummaryRow(ColumnDescriptor col, MedicalFileData data)
    {
        col.Item().PaddingBottom(8).Row(row =>
        {
            row.Spacing(6);
            MetricCard(row, "اسم الطفل", data.ChildName);
            MetricCard(row, "العمر الحالي", data.AgeLabel);
            MetricCard(row, "فصيلة الدم", data.BloodType);
            MetricCard(row, "حالة النمو العامة", data.GeneralGrowthLabel);
        });
    }

    private static void MetricCard(RowDescriptor row, string label, string value)
    {
        row.RelativeItem().Background(CardBg).Border(1).BorderColor(CardBorder)
            .PaddingVertical(6).PaddingHorizontal(7).Column(c =>
            {
                c.Item().Text(label).FontSize(8.2f).Bold().FontColor(MaroonLabel);
                c.Item().PaddingTop(2).Text(string.IsNullOrWhiteSpace(value) ? "—" : value)
                    .FontSize(10.5f).Bold().FontColor(TextDark);
            });
    }

    // قسم بعنوان (شريط عنوان عنابي + إطار)
    private static void SectionPanel(ColumnDescriptor col, string titleAr, string? titleEn, Action<IContainer> body)
    {
        col.Item().PaddingTop(8).Border(1).BorderColor(SectionBorder).Column(section =>
        {
            section.Item().Background(SectionTitleBg).Row(titleRow =>
            {
                titleRow.ConstantItem(5).Background(MaroonAccent);
                titleRow.RelativeItem().PaddingVertical(6).PaddingHorizontal(9).Text(t =>
                {
                    t.Span(titleAr).FontFamily(KufiFont).Bold().FontSize(12).FontColor(Maroon);
                    if (!string.IsNullOrEmpty(titleEn))
                        t.Span("  " + titleEn).FontSize(9.5f).SemiBold().FontColor("#8b3a43");
                });
            });

            section.Item().Element(body);
        });
    }

    private static void IdentitySection(ColumnDescriptor col, MedicalFileData data)
    {
        SectionPanel(col, "بيانات الهوية والطفل الأساسية", null, body =>
        {
            body.Table(table =>
            {
                table.ColumnsDefinition(cd =>
                {
                    cd.RelativeColumn(18); // label
                    cd.RelativeColumn(32); // value
                    cd.RelativeColumn(18); // label
                    cd.RelativeColumn(32); // value
                });

                LabelCell(table, "اسم الطفل بالكامل"); ValueCell(table, data.ChildName);
                LabelCell(table, "تاريخ الميلاد"); ValueCell(table, data.BirthDateLabel);

                LabelCell(table, "العمر الحالي"); ValueCell(table, data.AgeLabel);
                LabelCell(table, "فصيلة الدم"); ValueCell(table, data.BloodType);

                LabelCell(table, "اسم الوالد / ولي الأمر"); ValueCell(table, data.GuardianName);
                LabelCell(table, "رقم هاتف الطوارئ"); ValueCell(table, data.EmergencyPhone);
            });
        });
    }

    private static void LabelCell(TableDescriptor table, string text) =>
        table.Cell().Background(Maroon).Border(1).BorderColor(ThBorder)
            .PaddingVertical(6).PaddingHorizontal(7)
            .Text(text).FontColor("#ffffff").Bold().FontSize(9f);

    private static void ValueCell(TableDescriptor table, string? text) =>
        table.Cell().Border(1).BorderColor(TdBorder)
            .PaddingVertical(6).PaddingHorizontal(7)
            .Text(string.IsNullOrWhiteSpace(text) ? "—" : text).FontColor(TextBody).FontSize(9f);

    private static void GrowthSection(ColumnDescriptor col, MedicalFileData data)
    {
        SectionPanel(col, "مؤشرات النمو والقياسات الحيوية", "(Growth Tracker)", body =>
        {
            body.Table(table =>
            {
                table.ColumnsDefinition(cd =>
                {
                    cd.RelativeColumn(38); // القياس الحيوي
                    cd.RelativeColumn(62); // القيمة الحالية
                });

                Th(table, "القياس الحيوي");
                Th(table, "القيمة الحالية");

                int i = 0;
                foreach (var g in data.Growth)
                {
                    var bg = i++ % 2 == 1 ? RowAlt : "#ffffff";
                    table.Cell().Background(bg).Border(1).BorderColor(TdBorder).PaddingVertical(6).PaddingHorizontal(7)
                        .Text(g.Metric).Bold().FontColor(TextBody).FontSize(9f);
                    table.Cell().Background(bg).Border(1).BorderColor(TdBorder).PaddingVertical(6).PaddingHorizontal(7)
                        .Text(string.IsNullOrWhiteSpace(g.Value) ? "غير مسجل" : g.Value).FontColor(TextBody).FontSize(9f);
                }
            });
        });
    }

    private static void VaccineSection(ColumnDescriptor col, string titleAr, string titleEn, List<MedicalVaccineRow> rows, bool isOptional)
    {
        SectionPanel(col, titleAr, titleEn, body =>
        {
            body.Table(table =>
            {
                table.ColumnsDefinition(cd =>
                {
                    cd.RelativeColumn(isOptional ? 36 : 44); // الاسم
                    cd.RelativeColumn(isOptional ? 24 : 18); // العمر/الجرعة المستهدفة
                    cd.RelativeColumn(isOptional ? 18 : 23); // التاريخ
                    cd.RelativeColumn(isOptional ? 22 : 15); // الحالة
                });

                Th(table, "اسم التطعيم" + (isOptional ? " الإضافي" : ""));
                Th(table, isOptional ? "الجرعة المستهدفة" : "العمر المستهدف");
                Th(table, isOptional ? "تاريخ الجرعة" : "تاريخ أخذ الجرعة الفعلي");
                Th(table, isOptional ? "حالة وملاحظات الجرعة" : "الحالة");

                if (rows.Count == 0)
                {
                    table.Cell().ColumnSpan(4).Border(1).BorderColor(TdBorder)
                        .PaddingVertical(10).PaddingHorizontal(7).AlignCenter()
                        .Text(isOptional ? "لا توجد تطعيمات إضافية مسجلة" : "لا توجد تطعيمات مسجلة")
                        .FontColor(MetaText).FontSize(9f);
                    return;
                }

                int i = 0;
                foreach (var v in rows)
                {
                    var bg = i++ % 2 == 1 ? RowAlt : "#ffffff";
                    table.Cell().Background(bg).Border(1).BorderColor(TdBorder).PaddingVertical(6).PaddingHorizontal(7)
                        .Text(v.Name).FontColor(TextBody).FontSize(9f);
                    table.Cell().Background(bg).Border(1).BorderColor(TdBorder).PaddingVertical(6).PaddingHorizontal(7)
                        .Text(v.TargetLabel).FontColor(TextBody).FontSize(9f);
                    table.Cell().Background(bg).Border(1).BorderColor(TdBorder).PaddingVertical(6).PaddingHorizontal(7)
                        .Text(v.IsTaken ? v.DateLabel : "—").FontColor(TextBody).FontSize(9f);
                    table.Cell().Background(bg).Border(1).BorderColor(TdBorder).PaddingVertical(6).PaddingHorizontal(7)
                        .AlignCenter().Element(c => StatusBadge(c, v.IsTaken));
                }
            });
        });
    }

    private static void StatusBadge(IContainer container, bool taken)
    {
        var bg = taken ? OkBg : PendingBg;
        var fg = taken ? OkText : PendingText;
        var border = taken ? OkBorder : PendingBorder;
        var label = taken ? "✓ تم أخذها" : "لم تؤخذ بعد";

        container.Background(bg).Border(1).BorderColor(border)
            .PaddingVertical(2).PaddingHorizontal(7)
            .Text(label).FontColor(fg).Bold().FontSize(8.4f);
    }

    private static void Th(TableDescriptor table, string text) =>
        table.Cell().Background(Maroon).Border(1).BorderColor(ThBorder)
            .PaddingVertical(6).PaddingHorizontal(7)
            .Text(text).FontColor("#ffffff").Bold().FontSize(9.4f);

    private static void MedicalHistorySection(ColumnDescriptor col, MedicalFileData data)
    {
        SectionPanel(col, "السجل المرضي والتشخيصات السابقة داخل تطبيق أجيال", null, body =>
        {
            if (data.Consultations.Count == 0)
            {
                body.PaddingVertical(16).PaddingHorizontal(12).Column(c =>
                {
                    c.Item().AlignCenter().Text("لا توجد استشارات أو تشخيصات سابقة مسجلة حتى الآن")
                        .Bold().FontSize(10).FontColor(Maroon);
                    c.Item().PaddingTop(4).AlignCenter().Text(
                        "ستظهر هنا تشخيصات الأطباء والروشتات الإلكترونية والتوصيات المنزلية بعد إتمام الاستشارات داخل التطبيق.")
                        .FontSize(9f).FontColor(MetaText);
                });
                return;
            }

            body.Column(list =>
            {
                bool first = true;
                foreach (var con in data.Consultations)
                {
                    var item = list.Item().PaddingVertical(8).PaddingHorizontal(11);
                    if (!first) item = item.BorderTop(1).BorderColor("#eedadd");
                    first = false;
                    item.Element(c => ConsultationCard(c, con));
                }
            });
        });
    }

    private static void ConsultationCard(IContainer container, MedicalConsultationCard con)
    {
        container.Column(c =>
        {
            // ترويسة الاستشارة
            c.Item().PaddingBottom(5).BorderBottom(1).BorderColor(DashBorder).Row(r =>
            {
                r.RelativeItem().Text(con.Title).FontFamily(KufiFont).Bold().FontSize(11).FontColor(Maroon);
                if (!string.IsNullOrWhiteSpace(con.Tag))
                    r.ConstantItem(70).AlignLeft().Background(Maroon).PaddingVertical(3).PaddingHorizontal(9)
                        .AlignCenter().Text(con.Tag).FontColor("#ffffff").Bold().FontSize(8.2f);
            });

            Field(c, "الطبيب الفاحص:", con.DoctorName);
            Field(c, "التشخيص الطبي:", con.Diagnosis);
            if (con.Prescription.Count > 0)
            {
                c.Item().PaddingTop(3).Text("الروشتة الإلكترونية:").Bold().FontColor(Maroon).FontSize(9f);
                foreach (var line in con.Prescription)
                    c.Item().PaddingRight(8).Text("• " + line).FontColor(TextBody).FontSize(9f);
            }
            if (!string.IsNullOrWhiteSpace(con.Recommendations))
                Field(c, "التوصيات المنزلية:", con.Recommendations!);
        });
    }

    private static void Field(ColumnDescriptor c, string label, string value)
    {
        c.Item().PaddingTop(3).Text(label).Bold().FontColor(Maroon).FontSize(9f);
        c.Item().Text(string.IsNullOrWhiteSpace(value) ? "—" : value).FontColor(TextBody).FontSize(9f);
    }

    private static void SecurityNote(ColumnDescriptor col)
    {
        col.Item().PaddingTop(10).Border(1).BorderColor(SecurityBorder).Background(SecurityBg)
            .Padding(10).Row(row =>
            {
                // (RTL) أول عنصر يمين: مربع QR
                row.ConstantItem(94).Height(70).Border(2).BorderColor(QrBorder).AlignMiddle().Column(qr =>
                {
                    qr.Item().AlignCenter().Text("DYNAMIC").FontColor(QrText).Bold().FontSize(8.5f);
                    qr.Item().AlignCenter().Text("QR CODE").FontColor(QrText).Bold().FontSize(8.5f);
                    qr.Item().AlignCenter().Text("VERIFIED").FontColor(QrText).Bold().FontSize(8.5f);
                });

                row.RelativeItem().PaddingRight(12).Column(c =>
                {
                    c.Item().Text("ملاحظة أمنية وإخلاء مسؤولية:").Bold().FontColor(Maroon).FontSize(9.5f);
                    c.Item().PaddingTop(3).Text(
                        "هذا التقرير تم توليده آلياً بشكل مشفر بناءً على البيانات الصحية المدخلة والموثقة من قبل الوالدين، " +
                        "بالإضافة إلى السجلات الطبية والروشتات الإلكترونية الصادرة من الأطباء المعتمدين والمشتركين في منصة أجيال الرقمية. " +
                        "هذا الملف يعبر عن التاريخ الصحي للطفل حتى تاريخ تحديثه.")
                        .FontColor(TextBody).FontSize(8.8f);
                });
            });
    }
}
