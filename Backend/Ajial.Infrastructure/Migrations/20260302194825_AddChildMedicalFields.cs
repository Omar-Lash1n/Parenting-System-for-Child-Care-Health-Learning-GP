using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddChildMedicalFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "BloodType",
                table: "Children",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "HeadCircumference",
                table: "Children",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Height",
                table: "Children",
                type: "float",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "MedicalHistory",
                table: "Children",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Weight",
                table: "Children",
                type: "float",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "BloodType",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "HeadCircumference",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "Height",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "MedicalHistory",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "Weight",
                table: "Children");
        }
    }
}
