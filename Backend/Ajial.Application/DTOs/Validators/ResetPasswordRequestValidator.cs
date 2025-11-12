using System.Text.RegularExpressions;
using Ajial.Application.DTOs.Auth;

namespace Ajial.Application.Validators;

public class ResetPasswordRequestValidator
{
    private readonly List<string> _errors = new();

    public (bool IsValid, List<string> Errors) Validate(ResetPasswordRequestDto request)
    {
        _errors.Clear();

        // Validate Token
        ValidateToken(request.Token);

        // Validate New Password
        ValidatePassword(request.NewPassword);

        // Validate Confirm Password
        ValidateConfirmPassword(request.NewPassword, request.ConfirmPassword);

        return (!_errors.Any(), _errors);
    }

    private void ValidateToken(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            _errors.Add("رمز إعادة التعيين مطلوب");
        }
    }

    private void ValidatePassword(string password)
    {
        if (string.IsNullOrWhiteSpace(password))
        {
            _errors.Add("كلمة المرور الجديدة مطلوبة");
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

        if (!Regex.IsMatch(password, @"[A-Z]"))
        {
            _errors.Add("كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل");
        }

        if (!Regex.IsMatch(password, @"[a-z]"))
        {
            _errors.Add("كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل");
        }

        if (!Regex.IsMatch(password, @"\d"))
        {
            _errors.Add("كلمة المرور يجب أن تحتوي على رقم واحد على الأقل");
        }

        if (!Regex.IsMatch(password, @"[@$!%*?&#]"))
        {
            _errors.Add("كلمة المرور يجب أن تحتوي على رمز خاص واحد على الأقل (@$!%*?&#)");
        }
    }

    private void ValidateConfirmPassword(string password, string confirmPassword)
    {
        if (string.IsNullOrWhiteSpace(confirmPassword))
        {
            _errors.Add("تأكيد كلمة المرور مطلوب");
            return;
        }

        if (password != confirmPassword)
        {
            _errors.Add("كلمة المرور وتأكيدها غير متطابقتين");
        }
    }
}