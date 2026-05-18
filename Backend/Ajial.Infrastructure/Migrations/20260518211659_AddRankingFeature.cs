using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddRankingFeature : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "RankingCycles",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SeasonName = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    PublishedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    NextPublishAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RankingCycles", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "RankingEntries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    RankingCycleId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ParentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Stars = table.Column<int>(type: "int", nullable: false),
                    Rank = table.Column<int>(type: "int", nullable: false),
                    Badge = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RankingEntries", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RankingEntries_Parents_ParentId",
                        column: x => x.ParentId,
                        principalTable: "Parents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_RankingEntries_RankingCycles_RankingCycleId",
                        column: x => x.RankingCycleId,
                        principalTable: "RankingCycles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_RankingEntries_ParentId",
                table: "RankingEntries",
                column: "ParentId");

            migrationBuilder.CreateIndex(
                name: "IX_RankingEntries_RankingCycleId",
                table: "RankingEntries",
                column: "RankingCycleId");

            migrationBuilder.CreateIndex(
                name: "IX_RankingEntries_RankingCycleId_ParentId",
                table: "RankingEntries",
                columns: new[] { "RankingCycleId", "ParentId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RankingEntries");

            migrationBuilder.DropTable(
                name: "RankingCycles");
        }
    }
}
