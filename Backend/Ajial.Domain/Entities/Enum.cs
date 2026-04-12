namespace Ajial.Domain.Entities;

public enum UserType
{
    Parent = 1,
    Doctor = 2,
    Child = 3
}

public enum ParentGender
{
    Father = 1,  // أب
    Mother = 2,  // أم
    Educator  = 3    // مربي
}

public enum SpecialistStatus
{
    Pending = 1,    // في انتظار مراجعة الإدارة
    Approved = 2,   // تمت الموافقة
    Rejected = 3    // مرفوض
}

public enum HealthUnitType
{
    HealthUnit = 1,          // وحدة صحية
    Hospital = 2,            // مستشفى
    VaccinationCenter = 3    // مركز تطعيم
}