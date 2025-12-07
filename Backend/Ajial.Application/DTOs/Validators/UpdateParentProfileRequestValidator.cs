using Ajial.Application.DTOs. Parent;
using System.Text.RegularExpressions;

namespace Ajial.Application. Validators;

public class UpdateParentProfileRequestValidator
{
    public (bool IsValid, List<string> Errors) Validate(UpdateParentProfileRequestDto request)
    {
        var errors = new List<string>();

        // Check if at least one field is provided
        if (IsAllFieldsNull(request))
        {
            errors.Add("يجب تحديث حقل واحد على الأقل");
            return (false, errors);
        }

        // 1. Validate Full Name (if provided)
        if (request.FullName != null)
        {
            if (string.IsNullOrWhiteSpace(request.FullName))
            {
                errors. Add("الاسم الكامل لا يمكن أن يكون فارغاً");
            }
            else if (request.FullName. Trim().Length < 3)
            {
                errors.Add("الاسم الكامل يجب أن يكون 3 أحرف على الأقل");
            }
            else if (request.FullName.Trim().Length > 100)
            {
                errors. Add("الاسم الكامل يجب ألا يتجاوز 100 حرف");
            }
        }

        // 2. Validate Username (if provided)
        if (request. Username != null)
        {
            if (string.IsNullOrWhiteSpace(request.Username))
            {
                errors. Add("اسم المستخدم لا يمكن أن يكون فارغاً");
            }
            else if (request.Username. Trim().Length < 3)
            {
                errors.Add("اسم المستخدم يجب أن يكون 3 أحرف على الأقل");
            }
            else if (request.Username.Trim().Length > 50)
            {
                errors. Add("اسم المستخدم يجب ألا يتجاوز 50 حرف");
            }
            else if (! Regex.IsMatch(request. Username. Trim(), @"^[a-zA-Z0-9_]+$"))
            {
                errors.Add("اسم المستخدم يجب أن يحتوي على حروف وأرقام وشرطة سفلية فقط");
            }
        }

        // 3.  Validate Email (if provided)
        if (request.Email != null)
        {
            if (string.IsNullOrWhiteSpace(request.Email))
            {
                errors.Add("البريد الإلكتروني لا يمكن أن يكون فارغاً");
            }
            else if (! IsValidEmail(request.Email. Trim()))
            {
                errors.Add("البريد الإلكتروني غير صحيح");
            }
        }

        // 4. Validate Date of Birth (if provided)
        if (request.DateOfBirth. HasValue)
        {
            var age = CalculateAge(request. DateOfBirth.Value);
            
            if (age < 18)
            {
                errors.Add("يجب أن يكون عمر المستخدم 18 عاماً على الأقل");
            }
            else if (age > 120)
            {
                errors.Add("تاريخ الميلاد غير صحيح");
            }
        }

        // 5. Validate City ID (if provided)
        if (request.CityId.HasValue)
        {
            if (request.CityId. Value <= 0)
            {
                errors.Add("المدينة المختارة غير صحيحة");
            }
        }

        // 6. Validate Role (if provided)
        if (request. Role.HasValue)
        {
            if (request.Role. Value < 1 || request. Role.Value > 3)
            {
                errors.Add("من أنت؟ يجب أن يكون: 1=أب، 2=أم، 3=مربي");
            }
        }

        return (errors.Count == 0, errors);
    }

    /// <summary>
    /// Check if all fields are null (nothing to update)
    /// </summary>
    private bool IsAllFieldsNull(UpdateParentProfileRequestDto request)
    {
        return request.FullName == null &&
               request.Username == null &&
               request.Email == null &&
               request.CityId == null &&
               request.DateOfBirth == null &&
               request. Role == null;
    }

    /// <summary>
    /// Validate email format
    /// </summary>
    private bool IsValidEmail(string email)
    {
        try
        {
            var addr = new System.Net.Mail.MailAddress(email);
            return addr.Address == email;
        }
        catch
        {
            return false;
        }
    }

    /// <summary>
    /// Calculate age from date of birth
    /// </summary>
    private int CalculateAge(DateTime dateOfBirth)
    {
        var today = DateTime.UtcNow;
        var age = today. Year - dateOfBirth.Year;

        if (dateOfBirth. Date > today.AddYears(-age))
        {
            age--;
        }

        return age;
    }
}