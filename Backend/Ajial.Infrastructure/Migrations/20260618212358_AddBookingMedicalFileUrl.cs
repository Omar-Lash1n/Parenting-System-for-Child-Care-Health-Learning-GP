using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddBookingMedicalFileUrl : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "MedicalFileUrl",
                table: "Bookings",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "MedicalFileUrl",
                table: "Bookings");
        }
    }
}
