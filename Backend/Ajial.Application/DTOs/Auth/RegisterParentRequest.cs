using System.ComponentModel.DataAnnotations;

namespace Ajial.Application.DTOs.Auth;

public class RegisterParentRequest
{
    [Required(ErrorMessage = "الاسم الكامل مطلوب")]
    [StringLength(100, MinimumLength = 3, ErrorMessage = "الاسم الكامل يجب أن يكون بين 3 و 100 حرف")]
    public string FullName { get; set; } = string.Empty;

    [Required(ErrorMessage = "اسم المستخدم مطلوب")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "اسم المستخدم يجب أن يكون بين 3 و 50 حرف")]
    [RegularExpression(@"^[a-zA-Z0-9_]+$", ErrorMessage = "اسم المستخدم يجب أن يحتوي على حروف وأرقام فقط")]
    public string Username { get; set; } = string.Empty;

    [Required(ErrorMessage = "البريد الإلكتروني مطلوب")]
    [EmailAddress(ErrorMessage = "البريد الإلكتروني غير صحيح")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "كلمة المرور مطلوبة")]
    [StringLength(100, MinimumLength = 8, ErrorMessage = "كلمة المرور يجب أن تكون 8 أحرف على الأقل")]
    [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]{8,}$", 
        ErrorMessage = "كلمة المرور يجب أن تحتوي على حرف كبير وحرف صغير ورقم ورمز خاص")]
    public string Password { get; set; } = string.Empty;

    [Required(ErrorMessage = "المدينة مطلوبة")]
    public int CityId { get; set; }

    [Required(ErrorMessage = "تاريخ الميلاد مطلوب")]
    public DateTime DateOfBirth { get; set; }

    [Required(ErrorMessage = "من أنت مطلوب")]
    public int Gender { get; set; } // 1: Father, 2: Mother, 3: Other
}