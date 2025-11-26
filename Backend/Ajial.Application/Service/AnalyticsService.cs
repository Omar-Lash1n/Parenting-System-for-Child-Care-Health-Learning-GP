using Ajial.Application.DTOs.Analytics;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Ajlal.Application.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Ajial.Application.Services;

public class AnalyticsService : IAnalyticsService
{
    private readonly IUnitOfWork _unitOfWork;

    public AnalyticsService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<ApiResponse<List<ChildAnalyticsDto>>> GetAllChildrenAnalyticsAsync()
    {
        try
        {
            // Get all children with related data
            var children = await _unitOfWork.Children.GetAllAsync(query => 
                query.Include(c => c.Parent)
                     .ThenInclude(p => p.User)
                     .Include(c => c.Parent)
                     .ThenInclude(p => p.City)
            );

            var result = children.Select(child => new ChildAnalyticsDto
            {
                // Child Information
                ChildId = child.Id,
                ChildFullName = child.FullName,
                ChildBirthDate = child.BirthDate,
                ChildAge = child.Age,
                ChildGender = child.Gender,
                ChildProfileImageUrl = child.ProfileImageUrl,
                ChildLoginId = child.ChildLoginId,
                ChildHasAccount = !string.IsNullOrEmpty(child.ChildLoginId),
                ChildIsActive = child.IsActive,
                ChildCreatedAt = child.CreatedAt,
                ChildUpdatedAt = child.UpdatedAt,
                
                // Parent Information
                ParentId = child.Parent.Id,
                ParentUserId = child.Parent.UserId,
                ParentFullName = child.Parent.User.FullName,
                ParentUsername = child.Parent.User.Username,
                ParentEmail = child.Parent.User.Email,
                ParentGender = child.Parent.Gender.ToString(),
                ParentDateOfBirth = child.Parent.DateOfBirth,
                ParentAge = CalculateAge(child.Parent.DateOfBirth),
                ParentIsActive = child.Parent.User.IsActive,
                ParentCreatedAt = child.Parent.CreatedAt,
                
                // City Information
                CityId = child.Parent.CityId,
                CityName = child.Parent.City.Name,
                CityNameAr = child.Parent.City.NameAr,
                
                // Calculated Fields
                AgeGroup = GetAgeGroup(child.Age),
                DaysSinceRegistration = (DateTime.UtcNow - child.CreatedAt).Days,
                RegistrationMonth = child.CreatedAt.ToString("yyyy-MM"),
                RegistrationYear = child.CreatedAt.Year.ToString()
            }).ToList();

            return ApiResponse<List<ChildAnalyticsDto>>.SuccessResponse(
                result,
                $"تم جلب بيانات {result.Count} طفل بنجاح"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<List<ChildAnalyticsDto>>.FailureResponse(
                "حدث خطأ أثناء جلب بيانات الأطفال",
                new List<string> { ex.Message }
            );
        }
    }

    public async Task<ApiResponse<List<ParentChildrenFlatDto>>> GetParentsWithChildrenFlatAsync()
    {
        try
        {
            // Get all parents with their children
            var parents = await _unitOfWork.Parents.GetAllAsync(query =>
                query.Include(p => p.User)
                     .Include(p => p.City)
                     .Include(p => p.Children)
            );

            var result = new List<ParentChildrenFlatDto>();

            foreach (var parent in parents)
            {
                // Calculate parent statistics
                var totalChildren = parent.Children.Count;
                var activeChildren = parent.Children.Count(c => c.IsActive);
                var childrenWithAccounts = parent.Children.Count(c => !string.IsNullOrEmpty(c.ChildLoginId));

                if (parent.Children.Any())
                {
                    // Create one row per child
                    foreach (var child in parent.Children)
                    {
                        result.Add(new ParentChildrenFlatDto
                        {
                            // Parent Information
                            ParentId = parent.Id,
                            ParentUserId = parent.UserId,
                            ParentFullName = parent.User.FullName,
                            ParentUsername = parent.User.Username,
                            ParentEmail = parent.User.Email,
                            ParentGender = parent.Gender.ToString(),
                            ParentDateOfBirth = parent.DateOfBirth,
                            ParentAge = CalculateAge(parent.DateOfBirth),
                            ParentIsActive = parent.User.IsActive,
                            ParentCreatedAt = parent.CreatedAt,
                            
                            // City Information
                            CityId = parent.CityId,
                            CityName = parent.City.Name,
                            CityNameAr = parent.City.NameAr,
                            
                            // Parent Statistics
                            TotalChildren = totalChildren,
                            ActiveChildren = activeChildren,
                            ChildrenWithAccounts = childrenWithAccounts,
                            
                            // Child Information
                            ChildId = child.Id,
                            ChildFullName = child.FullName,
                            ChildBirthDate = child.BirthDate,
                            ChildAge = child.Age,
                            ChildGender = child.Gender,
                            ChildProfileImageUrl = child.ProfileImageUrl,
                            ChildLoginId = child.ChildLoginId,
                            ChildHasAccount = !string.IsNullOrEmpty(child.ChildLoginId),
                            ChildIsActive = child.IsActive,
                            ChildCreatedAt = child.CreatedAt,
                            ChildUpdatedAt = child.UpdatedAt,
                            
                            // Child Calculated Fields
                            ChildAgeGroup = GetAgeGroup(child.Age),
                            ChildDaysSinceRegistration = (DateTime.UtcNow - child.CreatedAt).Days
                        });
                    }
                }
                else
                {
                    // Parent with no children - still include one row
                    result.Add(new ParentChildrenFlatDto
                    {
                        // Parent Information
                        ParentId = parent.Id,
                        ParentUserId = parent.UserId,
                        ParentFullName = parent.User.FullName,
                        ParentUsername = parent.User.Username,
                        ParentEmail = parent.User.Email,
                        ParentGender = parent.Gender.ToString(),
                        ParentDateOfBirth = parent.DateOfBirth,
                        ParentAge = CalculateAge(parent.DateOfBirth),
                        ParentIsActive = parent.User.IsActive,
                        ParentCreatedAt = parent.CreatedAt,
                        
                        // City Information
                        CityId = parent.CityId,
                        CityName = parent.City.Name,
                        CityNameAr = parent.City.NameAr,
                        
                        // Parent Statistics
                        TotalChildren = 0,
                        ActiveChildren = 0,
                        ChildrenWithAccounts = 0,
                        
                        // No child data
                        ChildId = null,
                        ChildFullName = null,
                        ChildBirthDate = null,
                        ChildAge = null,
                        ChildGender = null,
                        ChildProfileImageUrl = null,
                        ChildLoginId = null,
                        ChildHasAccount = null,
                        ChildIsActive = null,
                        ChildCreatedAt = null,
                        ChildUpdatedAt = null,
                        ChildAgeGroup = null,
                        ChildDaysSinceRegistration = null
                    });
                }
            }

            return ApiResponse<List<ParentChildrenFlatDto>>.SuccessResponse(
                result,
                $"تم جلب بيانات {parents.Count()} ولي أمر و {result.Count(r => r.ChildId != null)} طفل"
            );
        }
        catch (Exception ex)
        {
            return ApiResponse<List<ParentChildrenFlatDto>>.FailureResponse(
                "حدث خطأ أثناء جلب بيانات أولياء الأمور والأطفال",
                new List<string> { ex.Message }
            );
        }
    }

    private int CalculateAge(DateTime birthDate)
    {
        var today = DateTime.UtcNow;
        var age = today.Year - birthDate.Year;
        if (birthDate.Date > today.AddYears(-age)) age--;
        return age;
    }

    private string GetAgeGroup(int age)
    {
        return age switch
        {
            <= 3 => "0-3",
            <= 7 => "4-7",
            <= 13 => "8-13",
            _ => "14+"
        };
    }
}