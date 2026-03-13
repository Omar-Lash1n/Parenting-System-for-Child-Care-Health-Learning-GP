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