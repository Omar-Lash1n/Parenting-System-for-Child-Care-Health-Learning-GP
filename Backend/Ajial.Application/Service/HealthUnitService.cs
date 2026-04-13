using Ajial.Application.DTOs.Common;
using Ajial.Application.DTOs.HealthUnit;
using Ajial.Application.Interfaces;
using Ajlal.Application.Interfaces;
using Ajial.Domain.Entities;
using Microsoft.Extensions.Logging;

namespace Ajial.Application.Service;

/// <summary>
/// Service implementation for health unit search with Haversine distance calculation
/// </summary>
public class HealthUnitService : IHealthUnitService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<HealthUnitService> _logger;

    public HealthUnitService(IUnitOfWork unitOfWork, ILogger<HealthUnitService> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    /// <inheritdoc />
    public async Task<ApiResponse<SearchHealthUnitsResponse>> SearchAsync(SearchHealthUnitsRequest request)
    {
        try
        {
            // ── Validate input ─────────────────────────────────────────
            var validationError = ValidateSearchRequest(request);
            if (validationError != null)
                return ApiResponse<SearchHealthUnitsResponse>.FailureResponse(validationError);

            // ── Normalize inputs ───────────────────────────────────────
            request.Keyword = request.Keyword?.Trim();
            if (request.Page < 1) request.Page = 1;
            if (request.PageSize < 1) request.PageSize = 20;
            if (request.PageSize > 50) request.PageSize = 50;
            if (request.RadiusKm <= 0) request.RadiusKm = 50;
            if (request.RadiusKm > 200) request.RadiusKm = 200;

            // ── Parse type filter ──────────────────────────────────────
            HealthUnitType? typeFilter = null;
            if (!string.IsNullOrEmpty(request.Type))
            {
                if (Enum.TryParse<HealthUnitType>(request.Type, true, out var parsedType))
                    typeFilter = parsedType;
                else
                    return ApiResponse<SearchHealthUnitsResponse>.FailureResponse("نوع المكان غير صالح. الأنواع المتاحة: HealthUnit, Hospital, VaccinationCenter");
            }

            // ── Validate CityId if provided ────────────────────────────
            if (request.CityId.HasValue)
            {
                var cityExists = await _unitOfWork.Cities.ExistsAsync(c => c.Id == request.CityId.Value && c.IsActive);
                if (!cityExists)
                    return ApiResponse<SearchHealthUnitsResponse>.FailureResponse("المحافظة غير موجودة");
            }

            // ── Query from repository ──────────────────────────────────
            var allUnits = await _unitOfWork.HealthUnits.FindAsync(hu => hu.IsActive);

            // ── Load cities for name mapping and keyword matching ──────
            // Cities are a small static list (~27 governorates), so an in-memory
            // dictionary lookup is cheaper than a join and lets the keyword filter
            // match on city name without depending on navigation-property loading.
            var cities = await _unitOfWork.Cities.GetAllAsync();
            var cityLookup = cities.ToDictionary(c => c.Id, c => c);

            // ── Apply filters (in-memory since dataset is small ~100-200 records) ──
            var filtered = allUnits.AsEnumerable();

            if (typeFilter.HasValue)
                filtered = filtered.Where(hu => hu.Type == typeFilter.Value);

            if (request.CityId.HasValue)
                filtered = filtered.Where(hu => hu.CityId == request.CityId.Value);

            if (!string.IsNullOrWhiteSpace(request.Keyword))
            {
                var keyword = request.Keyword.Length > 100 ? request.Keyword[..100] : request.Keyword;
                // Match on the unit's own name and on its city name (via CityId).
                // Address columns are intentionally excluded — Egyptian addresses often
                // contain other city names as part of road names (e.g. "طريق أسوان-القاهرة"
                // for a facility in Aswan), which produced false positives.
                filtered = filtered.Where(hu =>
                {
                    if (hu.NameAr.Contains(keyword, StringComparison.OrdinalIgnoreCase) ||
                        hu.NameEn.Contains(keyword, StringComparison.OrdinalIgnoreCase))
                    {
                        return true;
                    }

                    if (!cityLookup.TryGetValue(hu.CityId, out var city) || city == null)
                        return false;

                    return city.NameAr.Contains(keyword, StringComparison.OrdinalIgnoreCase)
                        || (city.Name != null && city.Name.Contains(keyword, StringComparison.OrdinalIgnoreCase));
                });
            }

            // ── Calculate distance and map to DTOs ─────────────────────
            bool hasCoordinates = request.Latitude.HasValue && request.Longitude.HasValue;
            var items = filtered.Select(hu =>
            {
                double? distanceKm = null;
                if (hasCoordinates)
                {
                    distanceKm = CalculateDistanceKm(
                        request.Latitude!.Value, request.Longitude!.Value,
                        hu.Latitude, hu.Longitude);
                }

                cityLookup.TryGetValue(hu.CityId, out var city);

                return new HealthUnitListItemDto
                {
                    Id = hu.Id,
                    NameAr = hu.NameAr,
                    NameEn = hu.NameEn,
                    Type = hu.Type.ToString(),
                    TypeAr = GetTypeArabicName(hu.Type),
                    AddressAr = hu.AddressAr,
                    AddressEn = hu.AddressEn,
                    CityId = hu.CityId,
                    CityNameAr = city?.NameAr ?? "",
                    CityNameEn = city?.Name ?? "",
                    Latitude = hu.Latitude,
                    Longitude = hu.Longitude,
                    Phone = hu.Phone,
                    DistanceKm = distanceKm.HasValue ? Math.Round(distanceKm.Value, 1) : null,
                    IsActive = hu.IsActive
                };
            }).ToList();

            // ── Filter by radius (only when coordinates provided) ──────
            if (hasCoordinates)
            {
                items = items
                    .Where(i => i.DistanceKm.HasValue && i.DistanceKm.Value <= request.RadiusKm)
                    .OrderBy(i => i.DistanceKm)
                    .ToList();
            }
            else
            {
                items = items
                    .OrderBy(i => i.CityNameAr)
                    .ThenBy(i => i.NameAr)
                    .ToList();
            }

            // ── Paginate ───────────────────────────────────────────────
            var totalCount = items.Count;
            var pagedItems = items
                .Skip((request.Page - 1) * request.PageSize)
                .Take(request.PageSize)
                .ToList();

            var response = new SearchHealthUnitsResponse
            {
                TotalCount = totalCount,
                Page = request.Page,
                PageSize = request.PageSize,
                Items = pagedItems
            };

            var message = totalCount > 0
                ? $"تم العثور على {totalCount} مكان"
                : "لا توجد أماكن قريبة في هذه المنطقة";

            _logger.LogInformation("Health unit search completed. Keyword: {Keyword}, CityId: {CityId}, Type: {Type}, Results: {Count}",
                request.Keyword, request.CityId, request.Type, totalCount);

            return ApiResponse<SearchHealthUnitsResponse>.SuccessResponse(response, message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error searching health units");
            return ApiResponse<SearchHealthUnitsResponse>.FailureResponse("حدث خطأ أثناء البحث عن أماكن التطعيم");
        }
    }

    /// <inheritdoc />
    public async Task<ApiResponse<HealthUnitDetailDto>> GetByIdAsync(int id, double? latitude = null, double? longitude = null)
    {
        try
        {
            var healthUnit = await _unitOfWork.HealthUnits.GetByIdAsync(id);

            if (healthUnit == null || !healthUnit.IsActive)
                return ApiResponse<HealthUnitDetailDto>.FailureResponse("المكان غير موجود");

            // Load city info
            var city = await _unitOfWork.Cities.GetByIdAsync(healthUnit.CityId);

            double? distanceKm = null;
            if (latitude.HasValue && longitude.HasValue)
            {
                distanceKm = CalculateDistanceKm(
                    latitude.Value, longitude.Value,
                    healthUnit.Latitude, healthUnit.Longitude);
            }

            var dto = new HealthUnitDetailDto
            {
                Id = healthUnit.Id,
                NameAr = healthUnit.NameAr,
                NameEn = healthUnit.NameEn,
                Type = healthUnit.Type.ToString(),
                TypeAr = GetTypeArabicName(healthUnit.Type),
                AddressAr = healthUnit.AddressAr,
                AddressEn = healthUnit.AddressEn,
                CityId = healthUnit.CityId,
                CityNameAr = city?.NameAr ?? "",
                CityNameEn = city?.Name ?? "",
                Latitude = healthUnit.Latitude,
                Longitude = healthUnit.Longitude,
                Phone = healthUnit.Phone,
                DistanceKm = distanceKm.HasValue ? Math.Round(distanceKm.Value, 1) : null,
                IsActive = healthUnit.IsActive,
                GoogleMapsUrl = $"https://www.google.com/maps/dir/?api=1&destination={healthUnit.Latitude},{healthUnit.Longitude}",
                Notes = healthUnit.Notes,
                IsVerified = healthUnit.IsVerified
            };

            return ApiResponse<HealthUnitDetailDto>.SuccessResponse(dto, "تم جلب بيانات المكان بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting health unit details. Id: {Id}", id);
            return ApiResponse<HealthUnitDetailDto>.FailureResponse("حدث خطأ أثناء جلب بيانات المكان");
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // Private helpers
    // ═══════════════════════════════════════════════════════════════════

    /// <summary>
    /// Validates the search request parameters
    /// </summary>
    private static string? ValidateSearchRequest(SearchHealthUnitsRequest request)
    {
        // If one coordinate is provided, both must be
        if ((request.Latitude.HasValue && !request.Longitude.HasValue) ||
            (!request.Latitude.HasValue && request.Longitude.HasValue))
        {
            return "يجب إرسال خط العرض وخط الطول معًا";
        }

        // Validate lat/lng ranges
        if (request.Latitude.HasValue)
        {
            if (request.Latitude.Value < -90 || request.Latitude.Value > 90)
                return "إحداثيات غير صالحة — خط العرض يجب أن يكون بين -90 و 90";
        }

        if (request.Longitude.HasValue)
        {
            if (request.Longitude.Value < -180 || request.Longitude.Value > 180)
                return "إحداثيات غير صالحة — خط الطول يجب أن يكون بين -180 و 180";
        }

        return null;
    }

    /// <summary>
    /// Haversine formula — calculates great-circle distance between two points on Earth
    /// Accurate to within ~0.3% for distances under 500 km
    /// </summary>
    public static double CalculateDistanceKm(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371.0; // Earth's mean radius in km

        var dLat = DegreesToRadians(lat2 - lat1);
        var dLon = DegreesToRadians(lon2 - lon1);

        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(DegreesToRadians(lat1)) * Math.Cos(DegreesToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

        return R * c;
    }

    private static double DegreesToRadians(double degrees)
    {
        return degrees * Math.PI / 180.0;
    }

    /// <summary>
    /// Maps HealthUnitType enum to Arabic display name
    /// </summary>
    private static string GetTypeArabicName(HealthUnitType type) => type switch
    {
        HealthUnitType.HealthUnit => "وحدة صحية",
        HealthUnitType.Hospital => "مستشفى",
        HealthUnitType.VaccinationCenter => "مركز تطعيم",
        _ => "غير محدد"
    };
}
