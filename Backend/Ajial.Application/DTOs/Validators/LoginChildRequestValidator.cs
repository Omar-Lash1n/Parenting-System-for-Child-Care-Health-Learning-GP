using Ajial.Application.DTOs.Auth;
using System.Text.RegularExpressions;

namespace Ajial.Application.Validators;

public class LoginChildRequestValidator
{
    private static readonly HashSet<string> ValidFruitCodes = new()
    {
        "apple2025", "banana2025", "orange2025", "grape2025", "pear2025",
        "strawberry2025", "watermelon2025", "pineapple2025", "fig2025", "lemon2025"
    };

    public (bool IsValid, List<string> Errors) Validate(LoginChildRequestDto request)
    {
        var errors = new List<string>();

        // 1. Validate ChildLoginId
        if (string.IsNullOrWhiteSpace(request.ChildLoginId))
        {
            errors.Add("اكتب رقمك"); // "Write your number" - matches Figma error
            return (false, errors);
        }

        // Trim the login ID
        request.ChildLoginId = request.ChildLoginId.Trim();

        // Check if it's numbers only
        if (!Regex.IsMatch(request.ChildLoginId, @"^\d+$"))
        {
            errors.Add("معرف الدخول يجب أن يحتوي على أرقام فقط");
            return (false, errors);
        }

        // Check length (4-10 digits based on your add child validation)
        if (request.ChildLoginId.Length < 4)
        {
            errors.Add("أكمل رقمك"); // "Complete your number" - matches Figma error
            return (false, errors);
        }

        if (request.ChildLoginId.Length > 10)
        {
            errors.Add("معرف الدخول طويل جداً");
            return (false, errors);
        }

        // 2. Validate FruitPasswordCodes
        if (request.FruitPasswordCodes == null || !request.FruitPasswordCodes.Any())
        {
            errors.Add("اختر الفواكه"); // "Choose the fruits" - matches Figma error
            return (false, errors);
        }

        // Check if exactly 5 fruits
        if (request.FruitPasswordCodes.Count < 5)
        {
            errors.Add("أكمل الفواكه"); // "Complete the fruits" - matches Figma error
            return (false, errors);
        }

        if (request.FruitPasswordCodes.Count > 5)
        {
            errors.Add("يجب اختيار 5 فواكه فقط");
            return (false, errors);
        }

        // 3. Validate each fruit code
        foreach (var fruitCode in request.FruitPasswordCodes)
        {
            if (string.IsNullOrWhiteSpace(fruitCode))
            {
                errors.Add("رمز الفاكهة فارغ");
                return (false, errors);
            }

            if (!ValidFruitCodes.Contains(fruitCode.Trim().ToLower()))
            {
                errors.Add($"رمز الفاكهة غير صالح: {fruitCode}");
                return (false, errors);
            }
        }

        return (true, errors);
    }
}