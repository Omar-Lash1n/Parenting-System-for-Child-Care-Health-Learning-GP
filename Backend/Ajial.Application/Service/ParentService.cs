using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.Parent;
using Ajial.Application.Interfaces;
using Ajial.Domain.Entities;
using Ajlal.Application.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Ajial.Application.Services;

public class ParentService : IParentService
{
    private readonly IUnitOfWork _unitOfWork;

    public ParentService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<ApiResponse<List<ParentAnalyticsDto>>> GetAllParentsForAnalyticsAsync()
    {
        try
        {
            // Get all parents with related data using Include
            var parents = await _unitOfWork.Parents
                .GetAllAsync(
                    include: query => query
                        .Include(p => p.User)
                        .Include(p => p.City)
                );

            if (parents == null || !parents.Any())
            {
                return ApiResponse<List<ParentAnalyticsDto>>.SuccessResponse(
                    new List<ParentAnalyticsDto>(),
                    "لا توجد بيانات"
                );
            }

            // Map to DTOs with calculated fields
            var analyticsData = parents.Select(parent => new ParentAnalyticsDto
            {
                // User Information
                UserId = parent.User.Id,
                FullName = parent.User.FullName,
                Username = parent.User.Username,
                Email = parent.User.Email,
                UserCreatedAt = parent.User.CreatedAt,
                UserUpdatedAt = parent.User.UpdatedAt,

                // Parent Information
                ParentId = parent.Id,
                DateOfBirth = parent.DateOfBirth,
                Age = CalculateAge(parent.DateOfBirth),
                Gender = parent.Gender == ParentGender.Father ? "Father" : "Mother",  // ✅ Fixed: Use ParentGender enum
                GenderCode = (int)parent.Gender,

                // City Information
                CityId = parent.City.Id,
                CityName = parent.City.Name,
                CityNameAr = parent.City.NameAr,
                CityIsActive = parent.City.IsActive,

                // Calculated Fields
                AccountAgeInDays = (DateTime.UtcNow - parent.User.CreatedAt).Days,
                AgeGroup = GetAgeGroup(CalculateAge(parent.DateOfBirth)),
                Region = GetRegion(parent.City.Name)
            }).ToList();

            return ApiResponse<List<ParentAnalyticsDto>>.SuccessResponse(
                analyticsData,
                $"تم استرجاع بيانات {analyticsData.Count} ولي أمر بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<List<ParentAnalyticsDto>>.FailureResponse(
                "حدث خطأ أثناء استرجاع البيانات",
                new List<string> { ex.Message }
            );
        }
    }

    // Helper method to calculate age
    private int CalculateAge(DateTime dateOfBirth)
    {
        var today = DateTime.UtcNow;
        var age = today.Year - dateOfBirth.Year;

        if (dateOfBirth.Date > today.AddYears(-age))
        {
            age--;
        }

        return age;
    }

    // Helper method to categorize age groups
    private string GetAgeGroup(int age)
    {
        return age switch
        {
            >= 18 and <= 25 => "18-25",
            >= 26 and <= 35 => "26-35",
            >= 36 and <= 45 => "36-45",
            >= 46 and <= 55 => "46-55",
            _ => "56+"
        };
    }

    // Helper method to get region based on city
    private string GetRegion(string cityName)
    {
        return cityName switch
        {
            "Cairo" => "Greater Cairo",
            "Giza" => "Greater Cairo",
            "Shubra El Kheima" => "Greater Cairo",
            "Alexandria" => "Mediterranean",
            "Port Said" => "Canal Zone",
            _ => "Other"
        };
    }
}