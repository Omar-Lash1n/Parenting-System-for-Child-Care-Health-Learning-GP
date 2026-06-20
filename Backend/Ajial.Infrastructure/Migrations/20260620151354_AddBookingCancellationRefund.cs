using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddBookingCancellationRefund : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "CancellationFeeAmount",
                table: "Bookings",
                type: "decimal(18,2)",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "RefundAmount",
                table: "Bookings",
                type: "decimal(18,2)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CancellationFeeAmount",
                table: "Bookings");

            migrationBuilder.DropColumn(
                name: "RefundAmount",
                table: "Bookings");
        }
    }
}
