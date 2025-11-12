using System.Text.RegularExpressions;
using Ajial.Application.DTOs.Auth;

namespace Ajial.Application.Validators;

public class ForgotPasswordRequestValidator
{
    private readonly List<string> _errors = new();

    public (bool IsValid, List<string> Errors) Validate(ForgotPasswordRequestDto request)
    {
        _errors.Clear();

        // Validate Email
        ValidateEmail(request.Email);

        return (!_errors.Any(), _errors);
    }

    private void ValidateEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            _errors.Add("البريد الإلكتروني مطلوب");
            return;
        }

        var emailRegex = @"^[^@\s]+@[^@\s]+\.[^@\s]+$";
        if (!Regex.IsMatch(email, emailRegex))
        {
            _errors.Add("البريد الإلكتروني غير صحيح");
        }
    }
}