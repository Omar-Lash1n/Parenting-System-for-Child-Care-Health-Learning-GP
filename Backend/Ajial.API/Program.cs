using System.Text;
using Ajial.Application.DTOs.Common;
using Ajial.Application.Interfaces;
using Ajial.Application.Service;
using Ajial.Application.Services;
using Ajial.Infrastructure.Data;
using Ajial.Infrastructure.Repository;
using Ajial.Infrastructure.Services;
using Ajlal.Application.Interfaces;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add Azure App Services Logging Provider
builder.Logging.AddAzureWebAppDiagnostics();

// Add services to the container.
builder.Services.AddControllers();
builder.Services.Configure<ApiBehaviorOptions>(options =>
{
    options.InvalidModelStateResponseFactory = context =>
    {
        var errors = context.ModelState.Values
            .SelectMany(v => v.Errors)
            .Select(e => e.ErrorMessage)
            .ToList();

        return new BadRequestObjectResult(ApiResponse<object>.FailureResponse("بيانات غير صحيحة", errors));
    };
});
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Ajial API",
        Version = "v1",
        Description = "API for Ajial Child Care Management System",
        Contact = new OpenApiContact
        {
            Name = "Ajial Team",
            Email = "support@ajial.com"
        }
    });

    // Add JWT Authentication to Swagger
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "JWT Authorization header using the Bearer scheme. Enter 'Bearer' [space] and then your token in the text input below.\n\nExample: \"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...\""
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });

});

// Database Configuration
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("AzureConnection"),
        sqlOptions =>
        {
            sqlOptions.MigrationsAssembly("Ajial.Infrastructure");
            sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 5,
                maxRetryDelay: TimeSpan.FromSeconds(30),
                errorNumbersToAdd: null);
        }));

// ✅ Unit of Work & Repositories
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

// ✅ Application Services
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IParentService, ParentService>();
builder.Services.AddScoped<IChildService, ChildService>();        // ✅ NEW - Child Management
builder.Services.AddScoped<IVoiceNoteService, VoiceNoteService>(); // ✅ Voice Note Upload
builder.Services.AddScoped<IVaccinationService, VaccinationService>(); // ✅ Vaccination Feature
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<ISpecialistService, SpecialistService>();
builder.Services.AddScoped<ISpecialistApplicationService, SpecialistApplicationService>();
builder.Services.AddScoped<IJwtTokenService, JwtTokenService>();
builder.Services.AddScoped<IAnalyticsService, AnalyticsService>();
builder.Services.AddScoped<IVaccinationReminderService, VaccinationReminderService>(); // ✅ Vaccination Reminder Page
builder.Services.AddScoped<IFcmService, FcmService>();                                  // ✅ Firebase Cloud Messaging
builder.Services.AddHostedService<VaccinationReminderBackgroundWorker>();               // ✅ Reminder Background Worker
builder.Services.AddScoped<ITaskCategoryService, TaskCategoryService>();                // ✅ Task Categories
builder.Services.AddScoped<ITaskService, TaskService>();                                // ✅ Task Management
builder.Services.AddHostedService<TaskReminderBackgroundWorker>();                      // ✅ Task Reminder Worker
builder.Services.AddScoped<IHealthUnitService, HealthUnitService>();                    // ✅ Health Unit Search
builder.Services.AddScoped<IChildTaskService, ChildTaskService>();                       // ✅ Child Tasks Feature
builder.Services.AddScoped<IPrizeService, PrizeService>();
builder.Services.AddScoped<IChildHomeService, ChildHomeService>();                      // ✅ Child Home Feature
builder.Services.AddScoped<IParentHomeService, ParentHomeService>();
builder.Services.AddScoped<IDailyQuestionService, DailyQuestionService>();
builder.Services.AddScoped<ILessonService, LessonService>();                  // ✅ Lesson Feature (التغذية التربوية)
builder.Services.AddScoped<IRankingService, RankingService>();                 // ✅ Ranking Feature (لوحة التكريم)
// ✅ Infrastructure Services
builder.Services.AddScoped<IImageService, AzureBlobImageService>(); // ✅ NEW - Image Upload to Azure
builder.Services.AddSingleton<IPasswordHasher, PasswordHasher>();
builder.Services.AddScoped<IParentService, ParentService>();

// ✅ JWT Authentication Configuration
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var secretKey = jwtSettings["SecretKey"];

if (string.IsNullOrEmpty(secretKey))
{
    throw new InvalidOperationException("JWT SecretKey is not configured in appsettings.json");
}

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidAudience = jwtSettings["Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),
        ClockSkew = TimeSpan.Zero // Remove default 5 minute tolerance
    };

    // ✅ Enhanced logging for authentication
    options.Events = new JwtBearerEvents
    {
        OnAuthenticationFailed = context =>
        {
            var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
            logger.LogError("Authentication failed: {Message}", context.Exception.Message);
            return Task.CompletedTask;
        },
        OnTokenValidated = context =>
        {
            var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
            logger.LogInformation("Token validated for user: {User}",
                context.Principal?.Identity?.Name ?? "Unknown");
            return Task.CompletedTask;
        }
    };
});

builder.Services.AddAuthorization();

// ✅ CORS Configuration
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

var app = builder.Build();

// ✅ Run migrations automatically on startup
ILogger<Program>? logger;
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    logger = services.GetRequiredService<ILogger<Program>>();

    try
    {
        var context = services.GetRequiredService<ApplicationDbContext>();

        if (context.Database.GetPendingMigrations().Any())
        {
            logger.LogInformation("🔄 Applying pending migrations...");
            context.Database.Migrate();
            logger.LogInformation("✅ Migrations applied successfully!");
        }
        else
        {
            logger.LogInformation("✅ Database is up to date!");
        }

        // ✅ Log configured services
        logger.LogInformation("📦 Registered Services:");
        logger.LogInformation("  - IChildService: ChildService");
        logger.LogInformation("  - IImageService: AzureBlobImageService");
        logger.LogInformation("  - Azure Storage Container: {Container}",
            app.Configuration["AzureStorage:ContainerName"] ?? "child-images");
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "❌ An error occurred while migrating the database.");
        throw;
    }
}

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Ajial API v1");
        c.RoutePrefix = "swagger";
        c.DocumentTitle = "Ajial API Documentation";
    });
}
else
{
    // Production Swagger (optional - remove if not needed in production)
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "Ajial API v1");
        c.RoutePrefix = "swagger";
    });
}

app.UseHttpsRedirection();

// ✅ CORS must come before Authentication/Authorization
app.UseCors("AllowAll");

// ✅ Authentication & Authorization middleware (ORDER MATTERS!)
app.UseAuthentication();  // Must come before UseAuthorization
app.UseAuthorization();

app.MapControllers();

// ✅ Log startup information
logger = app.Services.GetRequiredService<ILogger<Program>>();
logger.LogInformation("🚀 Ajial API Started Successfully!");
logger.LogInformation("📍 Environment: {Environment}", app.Environment.EnvironmentName);
logger.LogInformation("🔗 Swagger UI: https://localhost:7001/swagger");
logger.LogInformation("🗄️  Database: {Database}",
    app.Configuration.GetConnectionString("AzureConnection")?.Split(';')[0]);

app.Run();
