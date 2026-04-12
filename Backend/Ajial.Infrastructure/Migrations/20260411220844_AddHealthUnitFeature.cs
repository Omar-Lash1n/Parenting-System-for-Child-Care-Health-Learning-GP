using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddHealthUnitFeature : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "HealthUnits",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    NameAr = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    NameEn = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Type = table.Column<int>(type: "int", nullable: false),
                    AddressAr = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    AddressEn = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    CityId = table.Column<int>(type: "int", nullable: false),
                    Latitude = table.Column<double>(type: "float", nullable: false),
                    Longitude = table.Column<double>(type: "float", nullable: false),
                    Phone = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    Notes = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    DataSource = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    IsVerified = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_HealthUnits", x => x.Id);
                    table.ForeignKey(
                        name: "FK_HealthUnits_Cities_CityId",
                        column: x => x.CityId,
                        principalTable: "Cities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "IsVerified", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 1, "شارع 9، المعادي، القاهرة", null, 1, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.9602, 31.256900000000002, "وحدة صحة الأسرة - المعادي", "Family Health Unit - Maadi", "يعمل يوميًا من 8 ص حتى 2 م ما عدا الجمعة", "0225281234", 1, null },
                    { 2, "شارع الحجاز، مصر الجديدة، القاهرة", null, 1, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.087, 31.323, "مركز تطعيم حي مصر الجديدة", "Heliopolis Vaccination Center", "مركز تطعيم رئيسي - يعمل يوميًا", "0224171234", 3, null },
                    { 3, "شارع فاروق، حدائق القبة، القاهرة", null, 1, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.084, 31.2913, "وحدة صحة الأسرة - حدائق القبة", "Family Health Unit - Hadayek El-Qobba", "يعمل من 8 ص حتى 2 م", "0224501234", 1, null },
                    { 4, "شارع أحمد عرابي، العباسية، القاهرة", null, 1, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.0731, 31.279699999999998, "مستشفى الأطفال التخصصي - القاهرة", "Children's Specialized Hospital - Cairo", "مستشفى أطفال تخصصي يقدم خدمات التطعيم", "0226831234", 2, null },
                    { 5, "شارع الخليفة المأمون، عين شمس، القاهرة", null, 1, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.131, 31.327999999999999, "وحدة صحة الأسرة - عين شمس", "Family Health Unit - Ain Shams", "يعمل يوميًا من 8 ص حتى 2 م", "0224861234", 1, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[] { 6, "شارع الأمل، المرج، القاهرة", null, 1, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 30.152999999999999, 31.347000000000001, "وحدة صحة الأسرة - المرج", "Family Health Unit - El Marg", "يعمل يوميًا", "0244731234", 1, null });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "IsVerified", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 7, "شارع بورسعيد، السيدة زينب، القاهرة", null, 1, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.029, 31.236000000000001, "مركز تطعيم السيدة زينب", "Sayeda Zeinab Vaccination Center", "مركز تطعيم - يعمل كل يوم ما عدا الجمعة", "0223641234", 3, null },
                    { 8, "شارع منصور، حلوان، القاهرة", null, 1, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.841200000000001, 31.334, "وحدة صحة الأسرة - حلوان", "Family Health Unit - Helwan", "يعمل من 9 ص حتى 3 م", "0225561234", 1, null },
                    { 9, "شارع رمسيس، العباسية، القاهرة", null, 1, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.076000000000001, 31.283999999999999, "مستشفى حميات العباسية", "Abbassia Fever Hospital", "يقدم خدمات التطعيم ضد الأمراض المعدية", "0226821234", 2, null },
                    { 10, "شارع عباس العقاد، مدينة نصر، القاهرة", null, 1, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.051100000000002, 31.347999999999999, "وحدة صحة الأسرة - مدينة نصر", "Family Health Unit - Nasr City", "يعمل يوميًا من 8 ص حتى 2 م", "0222751234", 1, null },
                    { 11, "شارع خالد بن الوليد، سيدي بشر، الإسكندرية", null, 2, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.247, 29.981000000000002, "وحدة صحة الأسرة - سيدي بشر", "Family Health Unit - Sidi Bishr", "يعمل يوميًا من 8 ص حتى 2 م", "035461234", 1, null },
                    { 12, "شارع 14 مايو، سموحة، الإسكندرية", null, 2, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.210999999999999, 29.951000000000001, "مركز تطعيم سموحة", "Smouha Vaccination Center", "مركز تطعيم رئيسي", "034261234", 3, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[] { 13, "طريق الإسكندرية مطروح، العجمي، الإسكندرية", null, 2, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 31.138999999999999, 29.774999999999999, "وحدة صحة الأسرة - العجمي", "Family Health Unit - El Agami", "يعمل يوميًا", "034301234", 1, null });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "IsVerified", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 14, "شارع الجيش، الشاطبي، الإسكندرية", null, 2, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.207999999999998, 29.914999999999999, "مستشفى الأطفال الجامعي - الإسكندرية", "Alexandria University Children's Hospital", "مستشفى جامعي يقدم تطعيمات", "035901234", 2, null },
                    { 15, "شارع المعمورة، المنتزه، الإسكندرية", null, 2, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.286999999999999, 30.02, "وحدة صحة الأسرة - المنتزه", "Family Health Unit - Montazah", "يعمل من 8 ص حتى 2 م", "035471234", 1, null },
                    { 16, "شارع مصطفى كامل، محرم بك، الإسكندرية", null, 2, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.198, 29.911999999999999, "وحدة صحة الأسرة - محرم بك", "Family Health Unit - Moharem Bek", "يعمل يوميًا", "034951234", 1, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 17, "شارع الجمهورية، العامرية، الإسكندرية", null, 2, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 31.155999999999999, 29.829999999999998, "مركز تطعيم العامرية", "Amreya Vaccination Center", "مركز تطعيم - يعمل يوميًا ما عدا الجمعة", "034551234", 3, null },
                    { 18, "المدينة الصناعية، برج العرب، الإسكندرية", null, 2, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 30.855, 29.664000000000001, "وحدة صحة الأسرة - برج العرب", "Family Health Unit - Borg El Arab", "يعمل من 8 ص حتى 2 م", "034591234", 1, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "IsVerified", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 19, "شارع التحرير، الدقي، الجيزة", null, 3, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.038, 31.212, "وحدة صحة الأسرة - الدقي", "Family Health Unit - Dokki", "يعمل يوميًا من 8 ص حتى 2 م", "0237601234", 1, null },
                    { 20, "شارع فيصل، فيصل، الجيزة", null, 3, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.013000000000002, 31.184000000000001, "مركز تطعيم فيصل", "Faisal Vaccination Center", "مركز تطعيم رئيسي", "0237821234", 3, null },
                    { 21, "شارع الهرم، العمرانية، الجيزة", null, 3, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.013999999999999, 31.202000000000002, "وحدة صحة الأسرة - العمرانية", "Family Health Unit - Omraneya", "يعمل يوميًا", "0237891234", 1, null },
                    { 22, "الحوامدية، الجيزة", null, 3, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.890999999999998, 31.254000000000001, "مستشفى الحوامدية العام", "Hawamdeya General Hospital", "يقدم خدمات تطعيم للأطفال", "0238151234", 2, null },
                    { 23, "شارع ناهيا، بولاق الدكرور، الجيزة", null, 3, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.026, 31.196000000000002, "وحدة صحة الأسرة - بولاق الدكرور", "Family Health Unit - Boulaq El-Dakrour", "يعمل من 8 ص حتى 2 م", "0233591234", 1, null },
                    { 24, "شارع الهرم، الجيزة", null, 3, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.986999999999998, 31.155999999999999, "مركز تطعيم الهرم", "Haram Vaccination Center", "مركز تطعيم يعمل يوميًا", "0233761234", 3, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 25, "كرداسة، الجيزة", null, 3, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 30.030999999999999, 31.109999999999999, "وحدة صحة الأسرة - كرداسة", "Family Health Unit - Kerdasa", "يعمل يوميًا", "0238201234", 1, null },
                    { 26, "شارع الجمهورية، أوسيم، الجيزة", null, 3, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 30.113, 31.137, "وحدة صحة الأسرة - أوسيم", "Family Health Unit - Ossim", "يعمل من 8 ص حتى 2 م", "0238401234", 1, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "IsVerified", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 27, "شارع الجيش، حي الشرق، بورسعيد", null, 5, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.259, 32.301000000000002, "وحدة صحة الأسرة - حي الشرق", "Family Health Unit - East District", "يعمل يوميًا", "0663251234", 1, null },
                    { 28, "شارع 23 يوليو، بورسعيد", null, 5, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.262, 32.305999999999997, "مركز تطعيم بورسعيد", "Port Said Vaccination Center", "مركز تطعيم رئيسي", "0663401234", 3, null },
                    { 29, "شارع الجمهورية، بورسعيد", null, 5, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.260000000000002, 32.298999999999999, "مستشفى بورسعيد العام", "Port Said General Hospital", "مستشفى عام يقدم تطعيمات", "0663201234", 2, null },
                    { 30, "حي الأربعين، السويس", null, 6, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.968, 32.526000000000003, "وحدة صحة الأسرة - الأربعين", "Family Health Unit - Arbaeen", "يعمل يوميًا", "0623251234", 1, null },
                    { 31, "شارع الجيش، السويس", null, 6, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.966999999999999, 32.548999999999999, "مركز تطعيم السويس", "Suez Vaccination Center", "مركز تطعيم رئيسي", "0623181234", 3, null },
                    { 32, "شارع الجمهورية، السويس", null, 6, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.969000000000001, 32.536000000000001, "مستشفى السويس العام", "Suez General Hospital", "مستشفى عام", "0623101234", 2, null },
                    { 33, "شارع الجامعة، المنصورة", null, 7, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.042000000000002, 31.379999999999999, "وحدة صحة الأسرة - حي الجامعة", "Family Health Unit - University District", "يعمل يوميًا", "0502341234", 1, null },
                    { 34, "شارع الجمهورية، المنصورة", null, 7, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.044, 31.378, "مركز تطعيم المنصورة", "Mansoura Vaccination Center", "مركز تطعيم رئيسي", "0502501234", 3, null },
                    { 35, "شارع الجيش، المنصورة", null, 7, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.039999999999999, 31.381, "مستشفى الأطفال الجامعي - المنصورة", "Mansoura University Children's Hospital", "مستشفى جامعي يقدم تطعيمات", "0502301234", 2, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[] { 36, "طلخا، الدقهلية", null, 7, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 31.058, 31.382999999999999, "وحدة صحة الأسرة - طلخا", "Family Health Unit - Talkha", "يعمل يوميًا", "0502551234", 1, null });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "IsVerified", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 37, "شارع البحر، وسط طنطا", null, 9, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.7865, 31.000399999999999, "وحدة صحة الأسرة - وسط طنطا", "Family Health Unit - Central Tanta", "يعمل يوميًا", "0403341234", 1, null },
                    { 38, "شارع الجلاء، طنطا", null, 9, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.788, 31.001000000000001, "مركز تطعيم طنطا", "Tanta Vaccination Center", "مركز تطعيم رئيسي", "0403401234", 3, null },
                    { 39, "شارع الجيش، طنطا", null, 9, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.785, 30.998999999999999, "مستشفى طنطا الجامعي", "Tanta University Hospital", "مستشفى جامعي يقدم تطعيمات", "0403201234", 2, null },
                    { 40, "شارع بورسعيد، المحلة الكبرى", null, 8, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.9693, 31.166399999999999, "وحدة صحة الأسرة - المحلة الكبرى", "Family Health Unit - El Mahalla El Kubra", "يعمل يوميًا", "0402201234", 1, null },
                    { 41, "شارع الجمهورية، أسيوط", null, 10, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 27.180900000000001, 31.183700000000002, "وحدة صحة الأسرة - وسط أسيوط", "Family Health Unit - Central Asyut", "يعمل يوميًا", "0882341234", 1, null },
                    { 42, "شارع الجيش، أسيوط", null, 10, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 27.183, 31.184999999999999, "مركز تطعيم أسيوط", "Asyut Vaccination Center", "مركز تطعيم رئيسي", "0882401234", 3, null },
                    { 43, "شارع الجامعة، أسيوط", null, 10, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 27.1845, 31.176500000000001, "مستشفى أسيوط الجامعي", "Asyut University Hospital", "مستشفى جامعي يقدم تطعيمات", "0882301234", 2, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 44, "أبنوب، أسيوط", null, 10, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 27.268000000000001, 31.151, "وحدة صحة الأسرة - أبنوب", "Family Health Unit - Abnoub", "يعمل يوميًا", "0882551234", 1, null },
                    { 45, "ديروط، أسيوط", null, 10, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 27.543399999999998, 30.816600000000001, "وحدة صحة الأسرة - ديروط", "Family Health Unit - Dairut", "يعمل من 8 ص حتى 2 م", "0882601234", 1, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "IsVerified", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 46, "شارع الجمهورية، الفيوم", null, 11, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.308399999999999, 30.8428, "وحدة صحة الأسرة - وسط الفيوم", "Family Health Unit - Central Fayyum", "يعمل يوميًا", "0842341234", 1, null },
                    { 47, "شارع الحرية، الفيوم", null, 11, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.309999999999999, 30.844000000000001, "مركز تطعيم الفيوم", "Fayyum Vaccination Center", "مركز تطعيم رئيسي", "0842401234", 3, null },
                    { 48, "شارع الجيش، الفيوم", null, 11, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.306000000000001, 30.841000000000001, "مستشفى الفيوم العام", "Fayyum General Hospital", "مستشفى عام", "0842201234", 2, null },
                    { 49, "شارع الجلاء، الزقازيق", null, 12, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.587599999999998, 31.501999999999999, "وحدة صحة الأسرة - الزقازيق", "Family Health Unit - Zagazig", "يعمل يوميًا", "0552341234", 1, null },
                    { 50, "شارع أحمد عرابي، الزقازيق", null, 12, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.588000000000001, 31.503, "مركز تطعيم الزقازيق", "Zagazig Vaccination Center", "مركز تطعيم رئيسي", "0552401234", 3, null },
                    { 51, "شارع الجامعة، الزقازيق", null, 12, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.585000000000001, 31.506, "مستشفى الزقازيق الجامعي", "Zagazig University Hospital", "مستشفى جامعي يقدم تطعيمات", "0552301234", 2, null },
                    { 52, "شارع محمد علي، الإسماعيلية", null, 13, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.596499999999999, 32.271500000000003, "وحدة صحة الأسرة - الإسماعيلية", "Family Health Unit - Ismailia", "يعمل يوميًا", "0642341234", 1, null },
                    { 53, "شارع الجيش، الإسماعيلية", null, 13, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.597999999999999, 32.271999999999998, "مركز تطعيم الإسماعيلية", "Ismailia Vaccination Center", "مركز تطعيم رئيسي", "0642401234", 3, null },
                    { 54, "شارع كورنيش النيل، أسوان", null, 14, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 24.088899999999999, 32.899799999999999, "وحدة صحة الأسرة - وسط أسوان", "Family Health Unit - Central Aswan", "يعمل يوميًا", "0972341234", 1, null },
                    { 55, "شارع السوق، أسوان", null, 14, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 24.091000000000001, 32.899000000000001, "مركز تطعيم أسوان", "Aswan Vaccination Center", "مركز تطعيم رئيسي", "0972401234", 3, null },
                    { 56, "طريق أسوان-القاهرة، أسوان", null, 14, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 24.056000000000001, 32.917999999999999, "مستشفى أسوان الجامعي", "Aswan University Hospital", "مستشفى جامعي", "0972201234", 2, null },
                    { 57, "الحي الأول، مدينة 6 أكتوبر", null, 15, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.972999999999999, 30.917000000000002, "وحدة صحة الأسرة - الحي الأول", "Family Health Unit - 1st District", "يعمل يوميًا", "0238351234", 1, null },
                    { 58, "المحور المركزي، 6 أكتوبر", null, 15, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.972000000000001, 30.925000000000001, "مركز تطعيم 6 أكتوبر", "6th October Vaccination Center", "مركز تطعيم رئيسي", "0238401234", 3, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[] { 59, "الحي السابع، 6 أكتوبر", null, 15, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 29.963999999999999, 30.934999999999999, "وحدة صحة الأسرة - الحي السابع", "Family Health Unit - 7th District", "يعمل يوميًا", "0238551234", 1, null });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "IsVerified", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 60, "شارع الجمهورية، دمياط", null, 17, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.416499999999999, 31.813300000000002, "وحدة صحة الأسرة - وسط دمياط", "Family Health Unit - Central Damietta", "يعمل يوميًا", "0572341234", 1, null },
                    { 61, "شارع بورسعيد، دمياط", null, 17, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.417999999999999, 31.814, "مركز تطعيم دمياط", "Damietta Vaccination Center", "مركز تطعيم رئيسي", "0572401234", 3, null },
                    { 62, "شارع الجلاء، دمياط", null, 17, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.414999999999999, 31.812000000000001, "مستشفى دمياط العام", "Damietta General Hospital", "مستشفى عام", "0572201234", 2, null },
                    { 63, "شارع كورنيش النيل، المنيا", null, 18, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 28.0871, 30.761800000000001, "وحدة صحة الأسرة - وسط المنيا", "Family Health Unit - Central Minya", "يعمل يوميًا", "0862341234", 1, null },
                    { 64, "شارع الجمهورية، المنيا", null, 18, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 28.088999999999999, 30.763000000000002, "مركز تطعيم المنيا", "Minya Vaccination Center", "مركز تطعيم رئيسي", "0862401234", 3, null },
                    { 65, "شارع الجامعة، المنيا", null, 18, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 28.085000000000001, 30.759, "مستشفى المنيا الجامعي", "Minya University Hospital", "مستشفى جامعي", "0862201234", 2, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[] { 66, "ملوي، المنيا", null, 18, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 27.731000000000002, 30.841000000000001, "وحدة صحة الأسرة - ملوي", "Family Health Unit - Mallawi", "يعمل يوميًا", "0862551234", 1, null });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "IsVerified", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 67, "شارع الجمهورية، بني سويف", null, 19, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.066099999999999, 31.099399999999999, "وحدة صحة الأسرة - بني سويف", "Family Health Unit - Beni Suef", "يعمل يوميًا", "0822341234", 1, null },
                    { 68, "شارع الحرية، بني سويف", null, 19, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.068000000000001, 31.100999999999999, "مركز تطعيم بني سويف", "Beni Suef Vaccination Center", "مركز تطعيم رئيسي", "0822401234", 3, null },
                    { 69, "طريق القاهرة، بني سويف", null, 19, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 29.074999999999999, 31.096, "مستشفى بني سويف الجامعي", "Beni Suef University Hospital", "مستشفى جامعي", "0822201234", 2, null },
                    { 70, "شارع المحطة، الأقصر", null, 20, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 25.687200000000001, 32.639600000000002, "وحدة صحة الأسرة - وسط الأقصر", "Family Health Unit - Central Luxor", "يعمل يوميًا", "0952341234", 1, null },
                    { 71, "شارع كورنيش النيل، الأقصر", null, 20, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 25.689, 32.640999999999998, "مركز تطعيم الأقصر", "Luxor Vaccination Center", "مركز تطعيم رئيسي", "0952401234", 3, null },
                    { 72, "طريق الأقصر - أسوان، الأقصر", null, 20, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 25.670999999999999, 32.648000000000003, "مستشفى الأقصر الدولي", "Luxor International Hospital", "مستشفى دولي", "0952201234", 2, null },
                    { 73, "شارع المستشفى، سوهاج", null, 21, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 26.558800000000002, 31.694800000000001, "وحدة صحة الأسرة - شارع المستشفى", "Family Health Unit - Hospital Street", "يعمل يوميًا من 8 ص حتى 2 م", "0932341234", 1, null },
                    { 74, "شارع الجمهورية، سوهاج", null, 21, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 26.556000000000001, 31.692, "مركز تطعيم سوهاج", "Sohag Vaccination Center", "مركز تطعيم رئيسي", "0932401234", 3, null },
                    { 75, "شارع الجيش، سوهاج", null, 21, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 26.561, 31.696000000000002, "مركز تطعيم سوهاج 2", "Sohag Vaccination Center 2", "مركز تطعيم إضافي", "0932501234", 3, null },
                    { 76, "طريق سوهاج - قنا، سوهاج", null, 21, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 26.545000000000002, 31.702000000000002, "مستشفى سوهاج الجامعي", "Sohag University Hospital", "مستشفى جامعي يقدم تطعيمات", "0932201234", 2, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 77, "جرجا، سوهاج", null, 21, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 26.338000000000001, 31.890999999999998, "وحدة صحة الأسرة - جرجا", "Family Health Unit - Girga", "يعمل يوميًا", "0932551234", 1, null },
                    { 78, "أخميم، سوهاج", null, 21, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 26.568000000000001, 31.745000000000001, "وحدة صحة الأسرة - أخميم", "Family Health Unit - Akhmim", "يعمل يوميًا", "0932601234", 1, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "IsVerified", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 79, "شارع الجمهورية، قنا", null, 23, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 26.155100000000001, 32.716000000000001, "وحدة صحة الأسرة - وسط قنا", "Family Health Unit - Central Qena", "يعمل يوميًا", "0962341234", 1, null },
                    { 80, "شارع الكورنيش، قنا", null, 23, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 26.157, 32.716999999999999, "مركز تطعيم قنا", "Qena Vaccination Center", "مركز تطعيم رئيسي", "0962401234", 3, null },
                    { 81, "شارع الجيش، قنا", null, 23, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 26.154, 32.715000000000003, "مستشفى قنا العام", "Qena General Hospital", "مستشفى عام", "0962201234", 2, null },
                    { 82, "شارع فريد ندا، بنها", null, 30, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.466699999999999, 31.183700000000002, "وحدة صحة الأسرة - بنها", "Family Health Unit - Benha", "يعمل يوميًا", "0132341234", 1, null },
                    { 83, "شارع الجيش، بنها", null, 30, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.468, 31.184999999999999, "مركز تطعيم بنها", "Benha Vaccination Center", "مركز تطعيم رئيسي", "0132401234", 3, null },
                    { 84, "شارع الجامعة، بنها", null, 30, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.457000000000001, 31.178000000000001, "مستشفى بنها الجامعي", "Benha University Hospital", "مستشفى جامعي", "0132201234", 2, null },
                    { 85, "شارع الجمهورية، كفر الشيخ", null, 31, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.110700000000001, 30.938800000000001, "وحدة صحة الأسرة - كفر الشيخ", "Family Health Unit - Kafr El Sheikh", "يعمل يوميًا", "0472341234", 1, null },
                    { 86, "شارع بور سعيد، كفر الشيخ", null, 31, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.111999999999998, 30.940000000000001, "مركز تطعيم كفر الشيخ", "Kafr El Sheikh Vaccination Center", "مركز تطعيم رئيسي", "0472401234", 3, null },
                    { 87, "التجمع الخامس، القاهرة الجديدة", null, 33, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.007400000000001, 31.491299999999999, "وحدة صحة الأسرة - التجمع الخامس", "Family Health Unit - 5th Settlement", "يعمل يوميًا", "0228131234", 1, null },
                    { 88, "شارع التسعين، التجمع الخامس", null, 33, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.007999999999999, 31.495000000000001, "مركز تطعيم القاهرة الجديدة", "New Cairo Vaccination Center", "مركز تطعيم رئيسي", "0228201234", 3, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[] { 89, "التجمع الأول، القاهرة الجديدة", null, 33, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 30.029, 31.471, "وحدة صحة الأسرة - التجمع الأول", "Family Health Unit - 1st Settlement", "يعمل يوميًا", "0228301234", 1, null });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "IsVerified", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 90, "شارع أحمد عرابي، شبرا الخيمة", null, 4, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.126000000000001, 31.242999999999999, "وحدة صحة الأسرة - شبرا الخيمة", "Family Health Unit - Shubra El Kheima", "يعمل يوميًا", "0244511234", 1, null },
                    { 91, "شارع شبرا، شبرا الخيمة", null, 4, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.126999999999999, 31.245000000000001, "مركز تطعيم شبرا الخيمة", "Shubra El Kheima Vaccination Center", "مركز تطعيم رئيسي", "0244601234", 3, null },
                    { 92, "شارع الجمهورية، دمنهور", null, 16, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.034099999999999, 30.468599999999999, "وحدة صحة الأسرة - دمنهور", "Family Health Unit - Damanhur", "يعمل يوميًا", "0452341234", 1, null },
                    { 93, "شارع الحرية، دمنهور", null, 16, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.035, 30.469999999999999, "مركز تطعيم دمنهور", "Damanhur Vaccination Center", "مركز تطعيم رئيسي", "0452401234", 3, null },
                    { 94, "شارع الشيراتون، الغردقة", null, 24, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 27.1784, 33.831899999999997, "وحدة صحة الأسرة - الغردقة", "Family Health Unit - Hurghada", "يعمل يوميًا", "0653251234", 1, null },
                    { 95, "طريق الغردقة - سفاجا، الغردقة", null, 24, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 27.170000000000002, 33.826999999999998, "مستشفى الغردقة العام", "Hurghada General Hospital", "مستشفى عام يقدم تطعيمات", "0653201234", 2, null },
                    { 96, "هضبة أم السيد، شرم الشيخ", null, 32, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 27.915800000000001, 34.329999999999998, "وحدة صحة الأسرة - شرم الشيخ", "Family Health Unit - Sharm El Sheikh", "يعمل يوميًا", "0693601234", 1, null },
                    { 97, "خليج نعمة، شرم الشيخ", null, 32, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 27.905999999999999, 34.329000000000001, "مستشفى شرم الشيخ الدولي", "Sharm El Sheikh International Hospital", "مستشفى دولي يقدم تطعيمات", "0693501234", 2, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[] { 98, "الحي السكني، العاصمة الإدارية الجديدة", null, 34, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 30.019400000000001, 31.7639, "وحدة صحة الأسرة - الحي السكني", "Family Health Unit - Residential District", "يعمل يوميًا", "0228501234", 1, null });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "IsVerified", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 99, "شارع 23 يوليو، العريش", null, 25, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.128, 33.798000000000002, "وحدة صحة الأسرة - العريش", "Family Health Unit - El Arish", "يعمل يوميًا", "0682341234", 1, null },
                    { 100, "شارع الجيش، العريش", null, 25, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.129999999999999, 33.798999999999999, "مستشفى العريش العام", "El Arish General Hospital", "مستشفى عام", "0682201234", 2, null },
                    { 101, "شارع الإسكندرية، مرسى مطروح", null, 29, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.354299999999999, 27.237300000000001, "وحدة صحة الأسرة - مرسى مطروح", "Family Health Unit - Marsa Matruh", "يعمل يوميًا", "0462341234", 1, null },
                    { 102, "شارع الجمهورية، مرسى مطروح", null, 29, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 31.352, 27.234999999999999, "مستشفى مرسى مطروح العام", "Marsa Matruh General Hospital", "مستشفى عام", "0462201234", 2, null },
                    { 103, "المنطقة الأولى، العاشر من رمضان", null, 27, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.296900000000001, 31.746099999999998, "وحدة صحة الأسرة - العاشر من رمضان", "Family Health Unit - 10th of Ramadan", "يعمل يوميًا", "0554401234", 1, null }
                });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[] { 104, "المنطقة الصناعية، العاشر من رمضان", null, 27, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, 30.300000000000001, 31.748999999999999, "مركز تطعيم العاشر من رمضان", "10th of Ramadan Vaccination Center", "مركز تطعيم", "0554501234", 3, null });

            migrationBuilder.InsertData(
                table: "HealthUnits",
                columns: new[] { "Id", "AddressAr", "AddressEn", "CityId", "CreatedAt", "DataSource", "IsActive", "IsVerified", "Latitude", "Longitude", "NameAr", "NameEn", "Notes", "Phone", "Type", "UpdatedAt" },
                values: new object[,]
                {
                    { 105, "شارع جمال عبد الناصر، شبين الكوم", null, 22, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.5579, 31.009699999999999, "وحدة صحة الأسرة - شبين الكوم", "Family Health Unit - Shibin El Kom", "يعمل يوميًا", "0482341234", 1, null },
                    { 106, "شارع الجمهورية، شبين الكوم", null, 22, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.559000000000001, 31.010999999999999, "مركز تطعيم شبين الكوم", "Shibin El Kom Vaccination Center", "مركز تطعيم رئيسي", "0482401234", 3, null },
                    { 107, "شارع الجيش، شبين الكوم", null, 22, new DateTime(2026, 4, 11, 0, 0, 0, 0, DateTimeKind.Utc), "Manual Research", true, true, 30.555, 31.007999999999999, "مستشفى شبين الكوم التعليمي", "Shibin El Kom Teaching Hospital", "مستشفى تعليمي", "0482201234", 2, null }
                });

            migrationBuilder.CreateIndex(
                name: "IX_HealthUnits_CityId",
                table: "HealthUnits",
                column: "CityId");

            migrationBuilder.CreateIndex(
                name: "IX_HealthUnits_IsActive",
                table: "HealthUnits",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_HealthUnits_Latitude_Longitude",
                table: "HealthUnits",
                columns: new[] { "Latitude", "Longitude" });

            migrationBuilder.CreateIndex(
                name: "IX_HealthUnits_NameAr",
                table: "HealthUnits",
                column: "NameAr");

            migrationBuilder.CreateIndex(
                name: "IX_HealthUnits_Type",
                table: "HealthUnits",
                column: "Type");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "HealthUnits");
        }
    }
}
