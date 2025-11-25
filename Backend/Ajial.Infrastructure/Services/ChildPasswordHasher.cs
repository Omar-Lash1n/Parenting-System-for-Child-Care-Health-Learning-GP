using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;

namespace Ajial.Infrastructure.Services;

public class ChildPasswordHasher
{
    private readonly IPasswordHasher _passwordHasher;

    public ChildPasswordHasher(IPasswordHasher passwordHasher)
    {
        _passwordHasher = passwordHasher;
    }

    public string HashPassword(Child child, string password)
    {
        return _passwordHasher.HashPassword(password);
    }

    public bool VerifyPassword(Child child, string hashedPassword, string providedPassword)
    {
        return _passwordHasher.VerifyPassword(providedPassword, hashedPassword);
    }
}