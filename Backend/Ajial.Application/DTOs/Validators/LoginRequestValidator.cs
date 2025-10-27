using System.Text.RegularExpressions;
using Ajial.Application.DTOs.Auth;

namespace Ajial.Application.Validators;

public class LoginRequestValidator
{
    private readonly List<string> _errors = new();

    public (bool IsValid, List<string> Errors) Validate(LoginRequestDto request)
    {
        _errors.Clear();

        // Validate Username
        ValidateUsername(request.Username);

        // Validate Password
        ValidatePassword(request.Password);

        return (!_errors.Any(), _errors);
    }

    private void ValidateUsername(string username)
    {
        if (string.IsNullOrWhiteSpace(username))
        {
            _errors.Add("اسم المستخدم مطلوب");
            return;
        }

        if (username.Length < 3)
        {
            _errors.Add("اسم المستخدم يجب أن يكون 3 أحرف على الأقل");
        }

        if (username.Length > 50)
        {
            _errors.Add("اسم المستخدم يجب أن لا يتجاوز 50 حرف");
        }

        // Username should only contain alphanumeric and underscore
        if (!Regex.IsMatch(username, @"^[a-zA-Z0-9_]+$"))
        {
            _errors.Add("اسم المستخدم يجب أن يحتوي على حروف وأرقام فقط");
        }
    }

    private void ValidatePassword(string password)
    {
        if (string.IsNullOrWhiteSpace(password))
        {
            _errors.Add("كلمة المرور مطلوبة");
            return;
        }

        if (password.Length < 8)
        {
            _errors.Add("كلمة المرور يجب أن تكون 8 أحرف على الأقل");
        }

        if (password.Length > 100)
        {
            _errors.Add("كلمة المرور طويلة جداً");
        }
    }
}