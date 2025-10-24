using Ajial.Application.DTOs.Auth;
using Ajial.Application.Interfaces;
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
}