using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddIsProcessedAtTimeFlag : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsProcessedAtTime",
                table: "VaccinationAppointments",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateIndex(
                name: "IX_VaccinationAppointments_IsProcessedAtTime",
                table: "VaccinationAppointments",
                column: "IsProcessedAtTime");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_VaccinationAppointments_IsProcessedAtTime",
                table: "VaccinationAppointments");

            migrationBuilder.DropColumn(
                name: "IsProcessedAtTime",
                table: "VaccinationAppointments");
        }
    }
}
