using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddVaccinationAppointmentReminder : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DeviceToken",
                table: "Users",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "VaccinationAppointments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ChildId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    VaccinationMilestoneId = table.Column<int>(type: "int", nullable: false),
                    HealthUnit = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    AppointmentDateTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    NotifyOneDayBefore = table.Column<bool>(type: "bit", nullable: false),
                    NotifyThreeHoursBefore = table.Column<bool>(type: "bit", nullable: false),
                    CustomReminderEnabled = table.Column<bool>(type: "bit", nullable: false),
                    CustomReminderDateTime = table.Column<DateTime>(type: "datetime2", nullable: true),
                    IsAlarmEnabled = table.Column<bool>(type: "bit", nullable: false),
                    IsPushEnabled = table.Column<bool>(type: "bit", nullable: false),
                    IsProcessedOneDayBefore = table.Column<bool>(type: "bit", nullable: false),
                    IsProcessedThreeHoursBefore = table.Column<bool>(type: "bit", nullable: false),
                    IsProcessedCustom = table.Column<bool>(type: "bit", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VaccinationAppointments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_VaccinationAppointments_Children_ChildId",
                        column: x => x.ChildId,
                        principalTable: "Children",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_VaccinationAppointments_VaccinationMilestones_VaccinationMilestoneId",
                        column: x => x.VaccinationMilestoneId,
                        principalTable: "VaccinationMilestones",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_VaccinationAppointments_AppointmentDateTime",
                table: "VaccinationAppointments",
                column: "AppointmentDateTime");

            migrationBuilder.CreateIndex(
                name: "IX_VaccinationAppointments_ChildId_VaccinationMilestoneId",
                table: "VaccinationAppointments",
                columns: new[] { "ChildId", "VaccinationMilestoneId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_VaccinationAppointments_IsProcessedCustom",
                table: "VaccinationAppointments",
                column: "IsProcessedCustom");

            migrationBuilder.CreateIndex(
                name: "IX_VaccinationAppointments_IsProcessedOneDayBefore",
                table: "VaccinationAppointments",
                column: "IsProcessedOneDayBefore");

            migrationBuilder.CreateIndex(
                name: "IX_VaccinationAppointments_IsProcessedThreeHoursBefore",
                table: "VaccinationAppointments",
                column: "IsProcessedThreeHoursBefore");

            migrationBuilder.CreateIndex(
                name: "IX_VaccinationAppointments_VaccinationMilestoneId",
                table: "VaccinationAppointments",
                column: "VaccinationMilestoneId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "VaccinationAppointments");

            migrationBuilder.DropColumn(
                name: "DeviceToken",
                table: "Users");
        }
    }
}
