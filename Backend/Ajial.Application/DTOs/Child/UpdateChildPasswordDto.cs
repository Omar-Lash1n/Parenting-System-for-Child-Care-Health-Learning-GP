namespace Ajial.Application.DTOs.Child;

public class UpdateChildPasswordDto
{
    /// <summary>
    /// كلمة المرور الجديدة (5 فواكه)
    /// </summary>
    public List<string> NewFruitPasswordCodes { get; set; } = new();

    /// <summary>
    /// تأكيد كلمة المرور الجديدة (يجب أن تتطابق)
    /// </summary>
    public List<string> ConfirmFruitPasswordCodes { get; set; } = new();
}
