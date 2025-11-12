using Ajial.Application.Interfaces;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using Microsoft.Extensions.Configuration;

namespace Ajial.Infrastructure.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;

    public EmailService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public async Task SendPasswordResetEmailAsync(string toEmail, string resetToken, string userName)
    {
        try
        {
            var email = new MimeMessage();
            
            // From
            email.From.Add(new MailboxAddress(
                _configuration["EmailSettings:SenderName"] ?? "Ajial System",
                _configuration["EmailSettings:SenderEmail"] ?? "noreply@ajial.com"
            ));
            
            // To
            email.To.Add(new MailboxAddress(userName, toEmail));
            
            // Subject
            email.Subject = "إعادة تعيين كلمة المرور - نظام أجيال";

            // Body
            var bodyBuilder = new BodyBuilder
            {
                HtmlBody = $@"
                    <!DOCTYPE html>
                    <html dir='rtl' lang='ar'>
                    <head>
                        <meta charset='UTF-8'>
                        <style>
                            body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; direction: rtl; }}
                            .container {{ max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f5f5f5; }}
                            .content {{ background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }}
                            .header {{ text-align: center; color: #d32f2f; margin-bottom: 20px; }}
                            .token-box {{ background-color: #f0f0f0; padding: 15px; border-radius: 5px; margin: 20px 0; text-align: center; }}
                            .token {{ font-size: 24px; font-weight: bold; color: #d32f2f; letter-spacing: 2px; }}
                            .button {{ display: inline-block; padding: 12px 30px; background-color: #d32f2f; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }}
                            .footer {{ text-align: center; color: #666; font-size: 12px; margin-top: 20px; }}
                        </style>
                    </head>
                    <body>
                        <div class='container'>
                            <div class='content'>
                                <div class='header'>
                                    <h1>🔐 إعادة تعيين كلمة المرور</h1>
                                </div>
                                
                                <p>مرحباً <strong>{userName}</strong>,</p>
                                
                                <p>تلقينا طلباً لإعادة تعيين كلمة المرور الخاصة بحسابك في نظام أجيال.</p>
                                
                                <p>استخدم الرمز التالي لإعادة تعيين كلمة المرور:</p>
                                
                                <div class='token-box'>
                                    <div class='token'>{resetToken}</div>
                                </div>
                                
                                <p><strong>ملاحظات هامة:</strong></p>
                                <ul>
                                    <li>هذا الرمز صالح لمدة <strong>30 دقيقة فقط</strong></li>
                                    <li>يمكن استخدام الرمز <strong>مرة واحدة فقط</strong></li>
                                    <li>لا تشارك هذا الرمز مع أي شخص</li>
                                </ul>
                                
                                <p>إذا لم تطلب إعادة تعيين كلمة المرور، يرجى تجاهل هذه الرسالة.</p>
                                
                                <div class='footer'>
                                    <p>© 2025 نظام أجيال لرعاية الوالدين</p>
                                    <p>هذه رسالة تلقائية، يرجى عدم الرد عليها</p>
                                </div>
                            </div>
                        </div>
                    </body>
                    </html>
                "
            };

            email.Body = bodyBuilder.ToMessageBody();

            // Send email
            using (var smtp = new SmtpClient())
            {
                // For development: use Gmail SMTP
                await smtp.ConnectAsync(
                    _configuration["EmailSettings:SmtpServer"] ?? "smtp.gmail.com",
                    int.Parse(_configuration["EmailSettings:SmtpPort"] ?? "587"),
                    SecureSocketOptions.StartTls
                );

                await smtp.AuthenticateAsync(
                    _configuration["EmailSettings:Username"],
                    _configuration["EmailSettings:Password"]
                );

                await smtp.SendAsync(email);
                await smtp.DisconnectAsync(true);
            }
        }
        catch (Exception ex)
        {
            throw new Exception($"Failed to send email: {ex.Message}", ex);
        }
    }
}