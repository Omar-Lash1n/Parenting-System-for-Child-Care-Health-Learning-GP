using Ajial.Application.DTOs.Auth;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Ajial.Application.Validators;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;

namespace Ajial.Application.Services;

public class AuthService : IAuthService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasher _passwordHasher;

    public AuthService(IUnitOfWork unitOfWork, IPasswordHasher passwordHasher)
    {
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
    }

    public async Task<RegisterParentResponse> RegisterParentAsync(RegisterParentRequest request)
    {
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

            // Step 6: Create response
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
                LoginAt = DateTime.UtcNow
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
}