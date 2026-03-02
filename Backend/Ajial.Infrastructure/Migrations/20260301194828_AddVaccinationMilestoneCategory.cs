using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddVaccinationMilestoneCategory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Category",
                table: "VaccinationMilestones",
                type: "nvarchar(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "Main");

            migrationBuilder.UpdateData(
                table: "VaccinationMilestones",
                keyColumn: "Id",
                keyValue: 1,
                column: "Category",
                value: "Main");

            migrationBuilder.UpdateData(
                table: "VaccinationMilestones",
                keyColumn: "Id",
                keyValue: 2,
                column: "Category",
                value: "Main");

            migrationBuilder.UpdateData(
                table: "VaccinationMilestones",
                keyColumn: "Id",
                keyValue: 3,
                column: "Category",
                value: "Main");

            migrationBuilder.UpdateData(
                table: "VaccinationMilestones",
                keyColumn: "Id",
                keyValue: 4,
                column: "Category",
                value: "Main");

            migrationBuilder.UpdateData(
                table: "VaccinationMilestones",
                keyColumn: "Id",
                keyValue: 5,
                column: "Category",
                value: "Main");

            migrationBuilder.UpdateData(
                table: "VaccinationMilestones",
                keyColumn: "Id",
                keyValue: 6,
                column: "Category",
                value: "Main");

            migrationBuilder.UpdateData(
                table: "VaccinationMilestones",
                keyColumn: "Id",
                keyValue: 7,
                column: "Category",
                value: "Main");

            migrationBuilder.InsertData(
                table: "VaccinationMilestones",
                columns: new[] { "Id", "AgeInMonths", "Category", "IsActive", "NameAr", "NameEn", "SortOrder", "VaccinesAr", "VaccinesEn" },
                values: new object[,]
                {
                    { 8, 48, "Additional", true, "تطعيم أولى حضانة", "KG1 Vaccination", 8, "المكورات السحائية الثنائى", "Meningococcal Vaccine" },
                    { 9, 72, "Additional", true, "تطعيم أولى ابتدائى", "Grade 1 Vaccination", 9, "المكورات السحائية الثنائى", "Meningococcal Vaccine" },
                    { 10, 84, "Additional", true, "تطعيم ثانية ابتدائى", "Grade 2 Vaccination", 10, "الثنائى البكتيري", "DT Vaccine" },
                    { 11, 120, "Additional", true, "تطعيم رابعة ابتدائى", "Grade 4 Vaccination", 11, "الثنائى البكتيري", "DT Vaccine" },
                    { 12, 144, "Additional", true, "تطعيم أولى إعدادي", "Grade 7 Vaccination", 12, "المكورات السحائية الثنائى", "Meningococcal Vaccine" },
                    { 13, 180, "Additional", true, "تطعيم أولى ثانوي", "Grade 10 Vaccination", 13, "المكورات السحائية الثنائى", "Meningococcal Vaccine" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "VaccinationMilestones",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "VaccinationMilestones",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "VaccinationMilestones",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "VaccinationMilestones",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "VaccinationMilestones",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "VaccinationMilestones",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DropColumn(
                name: "Category",
                table: "VaccinationMilestones");
        }
    }
}
