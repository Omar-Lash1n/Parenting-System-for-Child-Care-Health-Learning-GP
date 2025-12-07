using Ajial.Application.DTOs. Parent;
using System.Text.RegularExpressions;

namespace Ajial.Application.DTOs.Validators;

public class ChangePasswordRequestValidator
{
    public (bool IsValid, List<string> Errors) Validate(ChangePasswordRequestDto request)
    {
        var errors = new List<string>();

        // 1. Validate current password
        if (string.IsNullOrWhiteSpace(request.CurrentPassword))
        {
            errors.Add("كلمة المرور الحالية مطلوبة");
        }

        // 2. Validate new password not empty
        if (string.IsNullOrWhiteSpace(request.NewPassword))
        {
            errors.Add("كلمة المرور الجديدة مطلوبة");
        }
        else
        {
            // 3. Validate password strength (same as registration)
            var passwordErrors = ValidatePasswordStrength(request.NewPassword);
            errors.AddRange(passwordErrors);
        }

        // 4.  Validate confirm password
        if (string.IsNullOrWhiteSpace(request.ConfirmNewPassword))
        {
            errors.Add("تأكيد كلمة المرور مطلوب");
        }
        else if (request.NewPassword != request.ConfirmNewPassword)
        {
            errors.Add("كلمة المرور الجديدة وتأكيدها غير متطابقين");
        }

        // 5. Validate new password is different from current
        if (! string.IsNullOrWhiteSpace(request.CurrentPassword) &&
            ! string.IsNullOrWhiteSpace(request.NewPassword) &&
            request.CurrentPassword == request.NewPassword)
        {
            errors.Add("كلمة المرور الجديدة يجب أن تكون مختلفة عن كلمة المرور الحالية");
        }

        return (errors.Count == 0, errors);
    }

    /// <summary>
    /// Validate password strength requirements (same as registration)
    /// </summary>
    private List<string> ValidatePasswordStrength(string password)
    {
        var errors = new List<string>();

        // Minimum 8 characters
        if (password.Length < 8)
        {
            errors.Add("كلمة المرور يجب أن تكون 8 أحرف على الأقل");
        }

        // Must contain uppercase letter
        if (! Regex.IsMatch(password, @"[A-Z]"))
        {
            errors.Add("كلمة المرور يجب أن تحتوي على حرف كبير واحد على الأقل");
        }

        // Must contain lowercase letter
        if (!Regex.IsMatch(password, @"[a-z]"))
        {
            errors.Add("كلمة المرور يجب أن تحتوي على حرف صغير واحد على الأقل");
        }

        // Must contain digit
        if (!Regex.IsMatch(password, @"[0-9]"))
        {
            errors.Add("كلمة المرور يجب أن تحتوي على رقم واحد على الأقل");
        }

        // Must contain special character
        if (!Regex.IsMatch(password, @"[^a-zA-Z0-9]"))
        {
            errors.Add("كلمة المرور يجب أن تحتوي على رمز خاص واحد على الأقل (@, #, $, %, إلخ)");
        }

        return errors;
    }
}