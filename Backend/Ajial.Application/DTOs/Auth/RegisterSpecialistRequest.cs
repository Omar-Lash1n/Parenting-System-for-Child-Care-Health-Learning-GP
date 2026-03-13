using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace Ajial.Application.DTOs.Auth;

public class RegisterSpecialistRequest
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

    [Required(ErrorMessage = "رقم الهاتف مطلوب")]
    [RegularExpression(@"^(\+20|0020|0)1[0-9]{9}$", ErrorMessage = "رقم الهاتف غير صحيح")]
    public string Phone { get; set; } = string.Empty;

    [Required(ErrorMessage = "كلمة المرور مطلوبة")]
    [StringLength(100, MinimumLength = 8, ErrorMessage = "كلمة المرور يجب أن تكون 8 أحرف على الأقل")]
    [RegularExpression(@"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]{8,}$",
        ErrorMessage = "كلمة المرور يجب أن تحتوي على حرف كبير وحرف صغير ورقم ورمز خاص")]
    public string Password { get; set; } = string.Empty;

    [Required(ErrorMessage = "صورة بطاقة الوجه الأمامي مطلوبة")]
    public IFormFile IdFrontImage { get; set; } = null!;

    public IFormFile? IdBackImage { get; set; }

    [Required(ErrorMessage = "التخصص مطلوب")]
    [StringLength(100, MinimumLength = 2, ErrorMessage = "التخصص يجب أن يكون بين 2 و 100 حرف")]
    public string Specialization { get; set; } = string.Empty;

    [Required(ErrorMessage = "صورة شهادة التخصص مطلوبة")]
    public IFormFile SpecializationCertificateImage { get; set; } = null!;

    [Required(ErrorMessage = "رقم ترخيص مزاولة المهنة مطلوب")]
    [StringLength(50, MinimumLength = 3, ErrorMessage = "رقم الترخيص يجب أن يكون بين 3 و 50 حرف")]
    public string PracticeLicenseNumber { get; set; } = string.Empty;

    [Required(ErrorMessage = "صورة ترخيص مزاولة المهنة مطلوبة")]
    public IFormFile PracticeLicenseImage { get; set; } = null!;

    [Required(ErrorMessage = "صورة كارنية النقابة مطلوبة")]
    public IFormFile UnionCardImage { get; set; } = null!;

    [Required(ErrorMessage = "الصورة الشخصية مطلوبة")]
    public IFormFile PersonalPhoto { get; set; } = null!;
}
