using Ajial.Application.DTOs.Parent;

namespace Ajial.Application.DTOs.Validators;

/// <summary>
/// Validator for delete parent account request
/// </summary>
public class DeleteParentAccountRequestValidator
{
    private const string RequiredConfirmationText = "حذف";
    private readonly List<string> _errors = new();

    public (bool IsValid, List<string> Errors) Validate(DeleteParentAccountRequestDto request)
    {
        _errors.Clear();

        ValidateConfirmationText(request.ConfirmationText);

        return (!_errors.Any(), _errors);
    }

    private void ValidateConfirmationText(string confirmationText)
    {
        if (string.IsNullOrWhiteSpace(confirmationText))
        {
            _errors.Add("يجب كتابة كلمة \"حذف\" لتأكيد حذف الحساب");
            return;
        }

        if (confirmationText.Trim() != RequiredConfirmationText)
        {
            _errors.Add("يجب كتابة كلمة \"حذف\" بشكل صحيح لتأكيد الحذف");
        }
    }
}
