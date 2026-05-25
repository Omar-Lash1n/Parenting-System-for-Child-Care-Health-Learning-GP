using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddClinicAndRemoteConsultation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Clinics",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SpecialistId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    GovernorateId = table.Column<int>(type: "int", nullable: true),
                    DistrictName = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    Address = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Phone = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: true),
                    WorkingHoursJson = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ExaminationPrice = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    ConsultationPrice = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    LicenseImageUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    SyndicateRegistrationImageUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    HazardousWasteImageUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    ExteriorImageUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    InteriorImageUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    Status = table.Column<int>(type: "int", nullable: false),
                    RejectionReason = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    SubmittedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ReviewedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ReviewedByUserId = table.Column<Guid>(type: "uniqueidentifier", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Clinics", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Clinics_Cities_GovernorateId",
                        column: x => x.GovernorateId,
                        principalTable: "Cities",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Clinics_Specialists_SpecialistId",
                        column: x => x.SpecialistId,
                        principalTable: "Specialists",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "RemoteConsultations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SpecialistId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SessionPrice = table.Column<decimal>(type: "decimal(18,2)", nullable: true),
                    SessionDurationMinutes = table.Column<int>(type: "int", nullable: true),
                    WaitingPeriodMinutes = table.Column<int>(type: "int", nullable: true),
                    WorkingHoursJson = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    Status = table.Column<int>(type: "int", nullable: false),
                    RejectionReason = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    SubmittedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ReviewedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    ReviewedByUserId = table.Column<Guid>(type: "uniqueidentifier", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RemoteConsultations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RemoteConsultations_Specialists_SpecialistId",
                        column: x => x.SpecialistId,
                        principalTable: "Specialists",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Clinics_GovernorateId",
                table: "Clinics",
                column: "GovernorateId");

            migrationBuilder.CreateIndex(
                name: "IX_Clinics_SpecialistId",
                table: "Clinics",
                column: "SpecialistId");

            migrationBuilder.CreateIndex(
                name: "IX_Clinics_Status",
                table: "Clinics",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_RemoteConsultations_SpecialistId",
                table: "RemoteConsultations",
                column: "SpecialistId");

            migrationBuilder.CreateIndex(
                name: "IX_RemoteConsultations_Status",
                table: "RemoteConsultations",
                column: "Status");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Clinics");

            migrationBuilder.DropTable(
                name: "RemoteConsultations");
        }
    }
}
