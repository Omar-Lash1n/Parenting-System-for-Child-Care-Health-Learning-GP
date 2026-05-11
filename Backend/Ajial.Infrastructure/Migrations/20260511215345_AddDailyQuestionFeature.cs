using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDailyQuestionFeature : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "StarsBalance",
                table: "Parents",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "DailyQuestions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false, defaultValueSql: "newid()"),
                    QuestionText = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    StarsReward = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    CreatedByAdminId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()"),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DailyQuestions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DailyQuestions_Users_CreatedByAdminId",
                        column: x => x.CreatedByAdminId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "DailyQuestionOptions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false, defaultValueSql: "newid()"),
                    DailyQuestionId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    OptionText = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: false),
                    IsCorrect = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    OrderIndex = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DailyQuestionOptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DailyQuestionOptions_DailyQuestions_DailyQuestionId",
                        column: x => x.DailyQuestionId,
                        principalTable: "DailyQuestions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "DailyQuestionAnswers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false, defaultValueSql: "newid()"),
                    DailyQuestionId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ParentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SelectedOptionId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    IsCorrect = table.Column<bool>(type: "bit", nullable: false),
                    StarsEarned = table.Column<int>(type: "int", nullable: false),
                    AnsweredAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DailyQuestionAnswers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DailyQuestionAnswers_DailyQuestionOptions_SelectedOptionId",
                        column: x => x.SelectedOptionId,
                        principalTable: "DailyQuestionOptions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_DailyQuestionAnswers_DailyQuestions_DailyQuestionId",
                        column: x => x.DailyQuestionId,
                        principalTable: "DailyQuestions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_DailyQuestionAnswers_Parents_ParentId",
                        column: x => x.ParentId,
                        principalTable: "Parents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DailyQuestionAnswers_DailyQuestionId",
                table: "DailyQuestionAnswers",
                column: "DailyQuestionId");

            migrationBuilder.CreateIndex(
                name: "IX_DailyQuestionAnswers_ParentId_DailyQuestionId",
                table: "DailyQuestionAnswers",
                columns: new[] { "ParentId", "DailyQuestionId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_DailyQuestionAnswers_SelectedOptionId",
                table: "DailyQuestionAnswers",
                column: "SelectedOptionId");

            migrationBuilder.CreateIndex(
                name: "IX_DailyQuestionOptions_DailyQuestionId",
                table: "DailyQuestionOptions",
                column: "DailyQuestionId");

            migrationBuilder.CreateIndex(
                name: "IX_DailyQuestions_CreatedByAdminId",
                table: "DailyQuestions",
                column: "CreatedByAdminId");

            migrationBuilder.CreateIndex(
                name: "IX_DailyQuestions_IsActive",
                table: "DailyQuestions",
                column: "IsActive",
                unique: true,
                filter: "[IsActive] = 1");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DailyQuestionAnswers");

            migrationBuilder.DropTable(
                name: "DailyQuestionOptions");

            migrationBuilder.DropTable(
                name: "DailyQuestions");

            migrationBuilder.DropColumn(
                name: "StarsBalance",
                table: "Parents");
        }
    }
}
