namespace Ajial.Application.Interfaces;

public interface IEmailService
{
    Task SendPasswordResetEmailAsync(string toEmail, string resetToken, string userName);
    Task SendEmailVerificationAsync(string toEmail, string verificationLink, string userName);
}