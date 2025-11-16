using System.Text.RegularExpressions;
using Ajial.Application.DTOs.Auth;

namespace Ajial.Application.Validators;

public class VerifyOtpRequestValidator
{
    private readonly List<string> _errors = new();

    public (bool IsValid, List<string> Errors) Validate(VerifyOtpRequestDto request)
    {
        _errors.Clear();

        // Validate Token
        ValidateToken(request.Token);

        return (!_errors.Any(), _errors);
    }

    private void ValidateToken(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            _errors.Add("الرمز مطلوب");
            return;
        }

        // Must be exactly 6 digits
        if (token.Length != 6)
        {
            _errors.Add("الرمز يجب أن يكون 6 أرقام");
            return;
        }

        // Must contain only numbers
        if (!Regex.IsMatch(token, @"^\d{6}$"))
        {
            _errors.Add("الرمز يجب أن يحتوي على أرقام فقط");
        }
    }
}