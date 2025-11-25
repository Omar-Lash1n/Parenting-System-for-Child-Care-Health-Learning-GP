using Ajial.Application.DTOs.Child;
using Microsoft.AspNetCore.Http;
using System.Text.RegularExpressions;

namespace Ajial.Application.Validators;

public class AddChildRequestValidator
{
    private readonly List<string> _errors = new();
    private readonly List<string> _validFruitCodes = new()
    {
        "apple2025", "banana2025", "orange2025", "grape2025", "pear2025",
        "strawberry2025", "watermelon2025", "pineapple2025", "fig2025", "lemon2025"
    };

    public (bool IsValid, List<string> Errors) Validate(AddChildRequestDto request)
    {
        _errors.Clear();

        ValidateFullName(request.FullName);
        ValidateBirthDate(request.BirthDate);
        ValidateGender(request.Gender);
        ValidateImage(request.ProfileImage);

        int age = CalculateAge(request.BirthDate);

        if (age >= 4 && age <= 13)
        {
            ValidateChildLoginId(request.ChildLoginId);
            ValidateFruitPassword(request.FruitPasswordCodes);
        }

        return (!_errors.Any(), _errors);
    }

    private void ValidateFullName(string fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName))
        {
            _errors.Add("اسم الطفل مطلوب");
            return;
        }

        if (fullName.Length < 2)
        {
            _errors.Add("اسم الطفل يجب أن يكون حرفين على الأقل");
        }

        if (fullName.Length > 100)
        {
            _errors.Add("اسم الطفل طويل جداً");
        }

        if (!Regex.IsMatch(fullName, @"^[\u0600-\u06FFa-zA-Z\s]+$"))
        {
            _errors.Add("اسم الطفل يجب أن يحتوي على حروف فقط");
        }

        if (!fullName.Contains(" "))
        {
            _errors.Add("يرجى إدخال الاسم الكامل");
        }
    }

    private void ValidateBirthDate(DateTime birthDate)
    {
        if (birthDate == default)
        {
            _errors.Add("تاريخ الميلاد مطلوب");
            return;
        }

        var today = DateTime.UtcNow.Date;

        if (birthDate.Date >= today)
        {
            _errors.Add("تاريخ الميلاد يجب أن يكون في الماضي");
            return;
        }

        if (birthDate < today.AddYears(-18))
        {
            _errors.Add("عمر الطفل يجب أن يكون أقل من 18 سنة");
        }
    }

    private void ValidateGender(string gender)
    {
        if (string.IsNullOrWhiteSpace(gender))
        {
            _errors.Add("الجنس مطلوب");
            return;
        }

        var validGenders = new[] { "ذكر", "أنثى", "Male", "Female", "male", "female" };
        if (!validGenders.Contains(gender))
        {
            _errors.Add("الجنس يجب أن يكون ذكر أو أنثى");
        }
    }

    private void ValidateImage(IFormFile? image)
    {
        if (image == null) return;

        const long maxFileSize = 5 * 1024 * 1024;
        if (image.Length > maxFileSize)
        {
            _errors.Add("حجم الصورة يجب أن يكون أقل من 5 ميجابايت");
        }

        if (image.Length == 0)
        {
            _errors.Add("الصورة فارغة");
            return;
        }

        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
        var extension = Path.GetExtension(image.FileName)?.ToLowerInvariant();

        if (string.IsNullOrEmpty(extension) || !allowedExtensions.Contains(extension))
        {
            _errors.Add("نوع الصورة يجب أن يكون JPG أو PNG أو GIF");
        }

        var allowedContentTypes = new[] { "image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp" };
        if (!allowedContentTypes.Contains(image.ContentType?.ToLowerInvariant()))
        {
            _errors.Add("نوع ملف الصورة غير صحيح");
        }
    }

    private void ValidateChildLoginId(string? childLoginId)
    {
        if (string.IsNullOrWhiteSpace(childLoginId))
        {
            _errors.Add("معرف تسجيل الدخول مطلوب للأعمار من 4 إلى 13 سنة");
            return;
        }

        if (childLoginId.Length < 4)
        {
            _errors.Add("معرف تسجيل الدخول يجب أن يكون 4 أحرف على الأقل");
        }

        if (childLoginId.Length > 20)
        {
            _errors.Add("معرف تسجيل الدخول طويل جداً");
        }

        if (!Regex.IsMatch(childLoginId, @"^[a-zA-Z0-9]+$"))
        {
            _errors.Add("معرف تسجيل الدخول يجب أن يحتوي على حروف وأرقام فقط");
        }
    }

    private void ValidateFruitPassword(List<string>? fruitCodes)
    {
        if (fruitCodes == null || !fruitCodes.Any())
        {
            _errors.Add("يجب اختيار 5 فواكه لكلمة المرور");
            return;
        }

        if (fruitCodes.Count != 5)
        {
            _errors.Add($"يجب اختيار 5 فواكه بالضبط");
            return;
        }

        foreach (var code in fruitCodes)
        {
            if (string.IsNullOrWhiteSpace(code))
            {
                _errors.Add("رمز الفاكهة لا يمكن أن يكون فارغاً");
                continue;
            }

            if (!_validFruitCodes.Contains(code))
            {
                _errors.Add($"رمز الفاكهة غير صحيح: {code}");
            }
        }
    }

    public static int CalculateAge(DateTime birthDate)
    {
        var today = DateTime.UtcNow.Date;
        int age = today.Year - birthDate.Year;
        if (birthDate.Date > today.AddYears(-age))
        {
            age--;
        }
        return age;
    }
}