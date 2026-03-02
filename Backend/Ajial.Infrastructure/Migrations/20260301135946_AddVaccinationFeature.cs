using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddVaccinationFeature : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "VaccinationMilestones",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    NameAr = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    NameEn = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    AgeInMonths = table.Column<int>(type: "int", nullable: false),
                    VaccinesAr = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    VaccinesEn = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VaccinationMilestones", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "ChildVaccinations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ChildId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    VaccinationMilestoneId = table.Column<int>(type: "int", nullable: false),
                    IsTaken = table.Column<bool>(type: "bit", nullable: false),
                    RecordedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChildVaccinations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChildVaccinations_Children_ChildId",
                        column: x => x.ChildId,
                        principalTable: "Children",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ChildVaccinations_VaccinationMilestones_VaccinationMilestoneId",
                        column: x => x.VaccinationMilestoneId,
                        principalTable: "VaccinationMilestones",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.InsertData(
                table: "VaccinationMilestones",
                columns: new[] { "Id", "AgeInMonths", "IsActive", "NameAr", "NameEn", "SortOrder", "VaccinesAr", "VaccinesEn" },
                values: new object[,]
                {
                    { 1, 0, true, "تطعيم الولادة", "Birth Vaccination", 1, "كبدي ب رضع, شلل اطفال فموي, طعم بي سي جي", "Hepatitis B, Oral Polio Vaccine, BCG" },
                    { 2, 2, true, "تطعيم شهرين", "2 Months Vaccination", 2, "شلل اطفال (فموي), الطعم الخماسي", "Oral Polio Vaccine, Pentavalent Vaccine" },
                    { 3, 4, true, "تطعيم 4 شهور", "4 Months Vaccination", 3, "شلل اطفال (فموي), الطعم الخماسي, شلل اطفال (حقن)", "Oral Polio Vaccine, Pentavalent Vaccine, IPV" },
                    { 4, 6, true, "تطعيم 6 شهور", "6 Months Vaccination", 4, "شلل اطفال (فموي), الطعم الخماسي, شلل اطفال (حقن)", "Oral Polio Vaccine, Pentavalent Vaccine, IPV" },
                    { 5, 9, true, "تطعيم 9 شهور", "9 Months Vaccination", 5, "شلل اطفال (فموي)", "Oral Polio Vaccine" },
                    { 6, 12, true, "تطعيم 12 شهر", "12 Months Vaccination", 6, "شلل اطفال (فموي), الثلاثى الفيروسي", "Oral Polio Vaccine, MMR" },
                    { 7, 18, true, "تطعيم 18 شهر", "18 Months Vaccination", 7, "شلل اطفال (فموي), الثلاثى الفيروسي", "Oral Polio Vaccine, MMR" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_ChildVaccinations_ChildId",
                table: "ChildVaccinations",
                column: "ChildId");

            migrationBuilder.CreateIndex(
                name: "IX_ChildVaccinations_ChildId_VaccinationMilestoneId",
                table: "ChildVaccinations",
                columns: new[] { "ChildId", "VaccinationMilestoneId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ChildVaccinations_VaccinationMilestoneId",
                table: "ChildVaccinations",
                column: "VaccinationMilestoneId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ChildVaccinations");

            migrationBuilder.DropTable(
                name: "VaccinationMilestones");
        }
    }
}
