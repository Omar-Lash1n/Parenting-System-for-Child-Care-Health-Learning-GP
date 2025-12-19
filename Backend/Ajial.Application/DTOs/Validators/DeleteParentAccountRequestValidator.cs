using Ajial.Application.DTOs.Parent;

namespace Ajial.Application.Validators;

/// <summary>
/// Validator for delete parent account request
/// </summary>
public class DeleteParentAccountRequestValidator
{
    private readonly List<string> _errors = new();

    public (bool IsValid, List<string> Errors) Validate(DeleteParentAccountRequestDto request)
    {
        _errors.Clear();

        ValidatePassword(request.Password);

        return (!_errors.Any(), _errors);
    }

    private void ValidatePassword(string password)
    {
        if (string.IsNullOrWhiteSpace(password))
        {
            _errors.Add("كلمة المرور مطلوبة لحذف الحساب");
        }
    }
}
