using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSpecialistEntity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Specialists",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Phone = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    Specialization = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PracticeLicenseNumber = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    IdFrontImageUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    IdBackImageUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    SpecializationCertificateImageUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    PracticeLicenseImageUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    UnionCardImageUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    PersonalPhotoUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    Status = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Specialists", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Specialists_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Specialists_PracticeLicenseNumber",
                table: "Specialists",
                column: "PracticeLicenseNumber",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Specialists_UserId",
                table: "Specialists",
                column: "UserId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Specialists");
        }
    }
}
