using Ajial.Application.DTOs.Auth;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Ajial.Application.Validators;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;
using Ajial.Domain.Entities;
using System.Security.Cryptography;

namespace Ajial.Application.Services;

public class AuthService : IAuthService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IEmailService _emailService;
    private readonly IJwtTokenService _jwtTokenService;  // ✅ NEW

    public AuthService(
        IUnitOfWork unitOfWork, 
        IPasswordHasher passwordHasher,
        IEmailService emailService,
        IJwtTokenService jwtTokenService)  // ✅ NEW
    {
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
        _emailService = emailService;
        _jwtTokenService = jwtTokenService;  // ✅ NEW
    }

    // ... (keep all other methods unchanged)

    public async Task<ApiResponse<LoginResponseDto>> LoginParentAsync(LoginRequestDto request)
    {
        try
        {
            // Step 1: Validate input
            var validator = new LoginRequestValidator();
            var (isValid, errors) = validator.Validate(request);

            if (!isValid)
            {
                return ApiResponse<LoginResponseDto>.FailureResponse(
                    "فشل في تسجيل الدخول",
                    errors
                );
            }

            // Step 2: Find user by username
            var user = await _unitOfWork.Users.GetFirstOrDefaultAsync(
                u => u.Username == request.Username.Trim()
            );

            if (user == null)
            {
                return ApiResponse<LoginResponseDto>.FailureResponse(
                    "فشل في تسجيل الدخول",
                    new List<string> { "اسم المستخدم أو كلمة المرور غير صحيحة" }
                );
            }

            // Step 3: Verify password
            bool isPasswordValid = _passwordHasher.VerifyPassword(request.Password, user.PasswordHash);

            if (!isPasswordValid)
            {
                return ApiResponse<LoginResponseDto>.FailureResponse(
                    "فشل في تسجيل الدخول",
                    new List<string> { "اسم المستخدم أو كلمة المرور غير صحيحة" }
                );
            }

            // Step 4: Check if user is a parent
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(
                p => p.UserId == user.Id
            );

            if (parent == null)
            {
                return ApiResponse<LoginResponseDto>.FailureResponse(
                    "فشل في تسجيل الدخول",
                    new List<string> { "المستخدم ليس ولي أمر" }
                );
            }

            // Step 5: Get city information
            var city = await _unitOfWork.Cities.GetByIdAsync(parent.CityId);

            if (city == null)
            {
                return ApiResponse<LoginResponseDto>.FailureResponse(
                    "فشل في تسجيل الدخول",
                    new List<string> { "بيانات المدينة غير موجودة" }
                );
            }

            // ✅ Step 6: Generate JWT Token
            var token = _jwtTokenService.GenerateToken(
                user.Id,
                user.Username,
                user.Email,
                user.UserType.ToString()
            );

            // Step 7: Create response
            var response = new LoginResponseDto
            {
                UserId = user.Id,
                ParentId = parent.Id,
                FullName = user.FullName,
                Username = user.Username,
                Email = user.Email,
                Gender = parent.Gender,
                CityName = city.Name,
                CityNameAr = city.NameAr,
                DateOfBirth = parent.DateOfBirth,
                Message = "تم تسجيل الدخول بنجاح",
                LoginAt = DateTime.UtcNow,
                Token = token  // ✅ NEW: Include token in response
            };

            return ApiResponse<LoginResponseDto>.SuccessResponse(
                response,
                "تم تسجيل الدخول بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<LoginResponseDto>.FailureResponse(
                "حدث خطأ أثناء تسجيل الدخول",
                new List<string> { ex.Message }
            );
        }
    }

    // ... (keep all ForgotPasswordAsync, ResetPasswordAsync, RegisterParentAsync methods unchanged)
    
    public async Task<ApiResponse<ForgotPasswordResponseDto>> ForgotPasswordAsync(
        ForgotPasswordRequestDto request)
    {
        // ... (keep existing implementation)
        try
        {
            // الخطوة 1: التحقق من صحة البيانات
            var validator = new ForgotPasswordRequestValidator();
            var (isValid, errors) = validator.Validate(request);

            if (!isValid)
            {
                return ApiResponse<ForgotPasswordResponseDto>.FailureResponse(
                    "فشل في معالجة الطلب",
                    errors
                );
            }

            // الخطوة 2: البحث عن المستخدم
            var user = await _unitOfWork.Users.GetFirstOrDefaultAsync(
                u => u.Email == request.Email.Trim().ToLower()
            );

            // ملاحظة أمنية: نرجع نفس الرسالة سواء وُجد المستخدم أم لا
            // لمنع الكشف عن البريد الإلكتروني المسجل
            if (user == null)
            {
                // نرجع نجاح ولكن لا نرسل إيميل
                return ApiResponse<ForgotPasswordResponseDto>.SuccessResponse(
                    new ForgotPasswordResponseDto
                    {
                        Message = "إذا كان البريد الإلكتروني مسجلاً، ستصلك رسالة لإعادة تعيين كلمة المرور",
                        Email = request.Email,
                        RequestedAt = DateTime.UtcNow
                    },
                    "تم معالجة الطلب بنجاح"
                );
            }

            // الخطوة 3: التحقق من أن المستخدم ولي أمر
            var parent = await _unitOfWork.Parents.GetFirstOrDefaultAsync(
                p => p.UserId == user.Id
            );

            if (parent == null)
            {
                return ApiResponse<ForgotPasswordResponseDto>.SuccessResponse(
                    new ForgotPasswordResponseDto
                    {
                        Message = "إذا كان البريد الإلكتروني مسجلاً، ستصلك رسالة لإعادة تعيين كلمة المرور",
                        Email = request.Email,
                        RequestedAt = DateTime.UtcNow
                    },
                    "تم معالجة الطلب بنجاح"
                );
            }

            // الخطوة 4: إلغاء جميع الرموز السابقة غير المستخدمة
            var existingTokens = await _unitOfWork.PasswordResetTokens
                .GetAllAsync();
            
            var userExistingTokens = existingTokens
                .Where(t => t.UserId == user.Id && !t.IsUsed)
                .ToList();

            foreach (var token in userExistingTokens)
            {
                token.IsUsed = true;
                token.UsedAt = DateTime.UtcNow;
                await _unitOfWork.PasswordResetTokens.UpdateAsync(token);
            }

            // الخطوة 5: إنشاء رمز إعادة تعيين جديد (6 أرقام)
            string resetToken = GenerateNumericToken(6);

            // الخطوة 6: حفظ الرمز في قاعدة البيانات
            var passwordResetToken = new PasswordResetToken
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                Token = resetToken,
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = DateTime.UtcNow.AddMinutes(30), // صالح لمدة 30 دقيقة
                IsUsed = false
            };

            await _unitOfWork.PasswordResetTokens.AddAsync(passwordResetToken);
            await _unitOfWork.SaveChangesAsync();

            // الخطوة 7: إرسال الإيميل
            try
            {
                await _emailService.SendPasswordResetEmailAsync(
                    user.Email,
                    resetToken,
                    user.FullName
                );
            }
            catch (Exception emailEx)
            {
                // فشل إرسال الإيميل
                return ApiResponse<ForgotPasswordResponseDto>.FailureResponse(
                    "فشل في إرسال البريد الإلكتروني",
                    new List<string> { "حدث خطأ أثناء إرسال رسالة إعادة التعيين. يرجى المحاولة لاحقاً." }
                );
            }

            // الخطوة 8: إرجاع الاستجابة
            var response = new ForgotPasswordResponseDto
            {
                Message = "تم إرسال رمز إعادة التعيين إلى بريدك الإلكتروني",
                Email = user.Email,
                RequestedAt = DateTime.UtcNow
            };

            return ApiResponse<ForgotPasswordResponseDto>.SuccessResponse(
                response,
                "تم إرسال رمز إعادة التعيين بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<ForgotPasswordResponseDto>.FailureResponse(
                "حدث خطأ أثناء معالجة الطلب",
                new List<string> { ex.Message }
            );
        }
    }

    public async Task<ApiResponse<ResetPasswordResponseDto>> ResetPasswordAsync(
        ResetPasswordRequestDto request)
    {
        // ... (keep existing implementation)
        try
        {
            // الخطوة 1: التحقق من صحة البيانات
            var validator = new ResetPasswordRequestValidator();
            var (isValid, errors) = validator.Validate(request);

            if (!isValid)
            {
                return ApiResponse<ResetPasswordResponseDto>.FailureResponse(
                    "فشل في إعادة تعيين كلمة المرور",
                    errors
                );
            }

            // الخطوة 2: البحث عن الرمز
            var resetToken = await _unitOfWork.PasswordResetTokens.GetFirstOrDefaultAsync(
                t => t.Token == request.Token.Trim()
            );

            if (resetToken == null)
            {
                return ApiResponse<ResetPasswordResponseDto>.FailureResponse(
                    "فشل في إعادة تعيين كلمة المرور",
                    new List<string> { "رمز إعادة التعيين غير صحيح" }
                );
            }

            // الخطوة 3: التحقق من أن الرمز لم يُستخدم
            if (resetToken.IsUsed)
            {
                return ApiResponse<ResetPasswordResponseDto>.FailureResponse(
                    "فشل في إعادة تعيين كلمة المرور",
                    new List<string> { "تم استخدام هذا الرمز مسبقاً" }
                );
            }

            // الخطوة 4: التحقق من أن الرمز لم ينتهِ
            if (resetToken.ExpiresAt < DateTime.UtcNow)
            {
                return ApiResponse<ResetPasswordResponseDto>.FailureResponse(
                    "فشل في إعادة تعيين كلمة المرور",
                    new List<string> { "انتهت صلاحية رمز إعادة التعيين. يرجى طلب رمز جديد" }
                );
            }

            // الخطوة 5: جلب المستخدم
            var user = await _unitOfWork.Users.GetByIdAsync(resetToken.UserId);

            if (user == null)
            {
                return ApiResponse<ResetPasswordResponseDto>.FailureResponse(
                    "فشل في إعادة تعيين كلمة المرور",
                    new List<string> { "المستخدم غير موجود" }
                );
            }

            // الخطوة 6: تشفير كلمة المرور الجديدة
            string newPasswordHash = _passwordHasher.HashPassword(request.NewPassword);

            // الخطوة 7: تحديث كلمة المرور
            user.PasswordHash = newPasswordHash;
            user.UpdatedAt = DateTime.UtcNow;
            await _unitOfWork.Users.UpdateAsync(user);

            // الخطوة 8: تعليم الرمز كمُستخدم
            resetToken.IsUsed = true;
            resetToken.UsedAt = DateTime.UtcNow;
            await _unitOfWork.PasswordResetTokens.UpdateAsync(resetToken);

            // الخطوة 9: حفظ التغييرات
            await _unitOfWork.SaveChangesAsync();

            // الخطوة 10: إرجاع الاستجابة
            var response = new ResetPasswordResponseDto
            {
                Message = "تم إعادة تعيين كلمة المرور بنجاح",
                Email = user.Email,
                ResetAt = DateTime.UtcNow
            };

            return ApiResponse<ResetPasswordResponseDto>.SuccessResponse(
                response,
                "تم إعادة تعيين كلمة المرور بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<ResetPasswordResponseDto>.FailureResponse(
                "حدث خطأ أثناء إعادة تعيين كلمة المرور",
                new List<string> { ex.Message }
            );
        }
    }

    private string GenerateNumericToken(int length)
    {
        var random = new Random();
        var token = string.Empty;
        
        for (int i = 0; i < length; i++)
        {
            token += random.Next(0, 10).ToString();
        }
        
        return token;
    }

    public async Task<RegisterParentResponse> RegisterParentAsync(RegisterParentRequest request)
    {
        // ... (keep existing implementation)
        // Validate date of birth (must be at least 18 years old)
        var age = DateTime.UtcNow.Year - request.DateOfBirth.Year;
        if (request.DateOfBirth > DateTime.UtcNow.AddYears(-age)) age--;
        
        if (age < 18)
        {
            throw new ArgumentException("يجب أن يكون عمر المستخدم 18 عامًا على الأقل");
        }

        // Check if username already exists
        var existingUsername = await _unitOfWork.Users.ExistsAsync(u => u.Username == request.Username);
        if (existingUsername)
        {
            throw new ArgumentException("اسم المستخدم موجود بالفعل");
        }

        // Check if email already exists
        var existingEmail = await _unitOfWork.Users.ExistsAsync(u => u.Email == request.Email);
        if (existingEmail)
        {
            throw new ArgumentException("البريد الإلكتروني موجود بالفعل");
        }

        // Verify city exists
        var cityExists = await _unitOfWork.Cities.ExistsAsync(c => c.Id == request.CityId && c.IsActive);
        if (!cityExists)
        {
            throw new ArgumentException("المدينة المختارة غير صحيحة");
        }

        // Validate gender
        if (!Enum.IsDefined(typeof(ParentGender), request.Gender))
        {
            throw new ArgumentException("من أنت؟ غير صحيح");
        }

        await _unitOfWork.BeginTransactionAsync();

        try
        {
            // Create User
            var user = new User
            {
                Id = Guid.NewGuid(),
                FullName = request.FullName,
                Username = request.Username,
                Email = request.Email.ToLower(),
                PasswordHash = _passwordHasher.HashPassword(request.Password),
                UserType = UserType.Parent,
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };

            await _unitOfWork.Users.AddAsync(user);

            // Create Parent profile
            var parent = new Parent
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                DateOfBirth = request.DateOfBirth,
                CityId = request.CityId,
                Gender = (ParentGender)request.Gender,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.Parents.AddAsync(parent);
            await _unitOfWork.SaveChangesAsync();
            await _unitOfWork.CommitTransactionAsync();

            return new RegisterParentResponse
            {
                UserId = user.Id,
                ParentId = parent.Id,
                FullName = user.FullName,
                Username = user.Username,
                Email = user.Email,
                Message = "تم إنشاء الحساب بنجاح",
                CreatedAt = user.CreatedAt
            };
        }
        catch
        {
            await _unitOfWork.RollbackTransactionAsync();
            throw;
        }
    }
}