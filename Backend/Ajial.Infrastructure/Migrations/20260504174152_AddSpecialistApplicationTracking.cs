using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSpecialistApplicationTracking : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "RejectionReason",
                table: "Specialists",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ReviewedAt",
                table: "Specialists",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "ReviewedByUserId",
                table: "Specialists",
                type: "uniqueidentifier",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "SubmittedAt",
                table: "Specialists",
                type: "datetime2",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "SpecialistStatusHistories",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SpecialistId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    FromStatus = table.Column<int>(type: "int", nullable: false),
                    ToStatus = table.Column<int>(type: "int", nullable: false),
                    Reason = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    ChangedByUserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ChangedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SpecialistStatusHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SpecialistStatusHistories_Specialists_SpecialistId",
                        column: x => x.SpecialistId,
                        principalTable: "Specialists",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Specialties",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    NameAr = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    NameEn = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Specialties", x => x.Id);
                });

            migrationBuilder.InsertData(
                table: "Specialties",
                columns: new[] { "Id", "IsActive", "NameAr", "NameEn" },
                values: new object[,]
                {
                    { 1, true, "طبيب عام", "General Practitioner" },
                    { 2, true, "متخصص تربوي", "Educational Specialist" },
                    { 3, true, "طبيب أطفال", "Pediatrician" },
                    { 4, true, "أخصائي تغذية", "Nutritionist" },
                    { 5, true, "أخصائي نفسي", "Psychologist" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_SpecialistStatusHistories_ChangedAt",
                table: "SpecialistStatusHistories",
                column: "ChangedAt");

            migrationBuilder.CreateIndex(
                name: "IX_SpecialistStatusHistories_SpecialistId",
                table: "SpecialistStatusHistories",
                column: "SpecialistId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SpecialistStatusHistories");

            migrationBuilder.DropTable(
                name: "Specialties");

            migrationBuilder.DropColumn(
                name: "RejectionReason",
                table: "Specialists");

            migrationBuilder.DropColumn(
                name: "ReviewedAt",
                table: "Specialists");

            migrationBuilder.DropColumn(
                name: "ReviewedByUserId",
                table: "Specialists");

            migrationBuilder.DropColumn(
                name: "SubmittedAt",
                table: "Specialists");
        }
    }
}
