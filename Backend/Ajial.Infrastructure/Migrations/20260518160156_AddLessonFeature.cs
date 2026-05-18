using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddLessonFeature : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "LessonCategories",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    NameAr = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    NameEn = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    OrderIndex = table.Column<int>(type: "int", nullable: false),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LessonCategories", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "Lessons",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CategoryId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TitleAr = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    ContentAr = table.Column<string>(type: "nvarchar(max)", maxLength: 10000, nullable: false),
                    ImageUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    VideoUrl = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    IsActive = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    CreatedByAdminId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Lessons", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Lessons_LessonCategories_CategoryId",
                        column: x => x.CategoryId,
                        principalTable: "LessonCategories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Lessons_Users_CreatedByAdminId",
                        column: x => x.CreatedByAdminId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "LessonProgresses",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ParentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    LessonId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    IsRead = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    ReadAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    IsQuizCompleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    QuizCompletedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    TotalStarsEarned = table.Column<int>(type: "int", nullable: false, defaultValue: 0)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LessonProgresses", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LessonProgresses_Lessons_LessonId",
                        column: x => x.LessonId,
                        principalTable: "Lessons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_LessonProgresses_Parents_ParentId",
                        column: x => x.ParentId,
                        principalTable: "Parents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LessonQuestions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    LessonId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    QuestionText = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false),
                    StarsReward = table.Column<int>(type: "int", nullable: false),
                    OrderIndex = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LessonQuestions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LessonQuestions_Lessons_LessonId",
                        column: x => x.LessonId,
                        principalTable: "Lessons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LessonQuestionOptions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    LessonQuestionId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    OptionText = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: false),
                    IsCorrect = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    OrderIndex = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LessonQuestionOptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LessonQuestionOptions_LessonQuestions_LessonQuestionId",
                        column: x => x.LessonQuestionId,
                        principalTable: "LessonQuestions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "LessonQuestionAnswers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ParentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    LessonQuestionId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    SelectedOptionId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    IsCorrect = table.Column<bool>(type: "bit", nullable: false),
                    StarsEarned = table.Column<int>(type: "int", nullable: false),
                    AnsweredAt = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "SYSUTCDATETIME()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LessonQuestionAnswers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LessonQuestionAnswers_LessonQuestionOptions_SelectedOptionId",
                        column: x => x.SelectedOptionId,
                        principalTable: "LessonQuestionOptions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_LessonQuestionAnswers_LessonQuestions_LessonQuestionId",
                        column: x => x.LessonQuestionId,
                        principalTable: "LessonQuestions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_LessonQuestionAnswers_Parents_ParentId",
                        column: x => x.ParentId,
                        principalTable: "Parents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_LessonCategories_IsActive",
                table: "LessonCategories",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_LessonProgresses_LessonId",
                table: "LessonProgresses",
                column: "LessonId");

            migrationBuilder.CreateIndex(
                name: "IX_LessonProgresses_ParentId_LessonId",
                table: "LessonProgresses",
                columns: new[] { "ParentId", "LessonId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LessonQuestionAnswers_LessonQuestionId",
                table: "LessonQuestionAnswers",
                column: "LessonQuestionId");

            migrationBuilder.CreateIndex(
                name: "IX_LessonQuestionAnswers_ParentId_LessonQuestionId",
                table: "LessonQuestionAnswers",
                columns: new[] { "ParentId", "LessonQuestionId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LessonQuestionAnswers_SelectedOptionId",
                table: "LessonQuestionAnswers",
                column: "SelectedOptionId");

            migrationBuilder.CreateIndex(
                name: "IX_LessonQuestionOptions_LessonQuestionId",
                table: "LessonQuestionOptions",
                column: "LessonQuestionId");

            migrationBuilder.CreateIndex(
                name: "IX_LessonQuestions_LessonId",
                table: "LessonQuestions",
                column: "LessonId");

            migrationBuilder.CreateIndex(
                name: "IX_Lessons_CategoryId",
                table: "Lessons",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_Lessons_CreatedByAdminId",
                table: "Lessons",
                column: "CreatedByAdminId");

            migrationBuilder.CreateIndex(
                name: "IX_Lessons_IsActive",
                table: "Lessons",
                column: "IsActive");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LessonProgresses");

            migrationBuilder.DropTable(
                name: "LessonQuestionAnswers");

            migrationBuilder.DropTable(
                name: "LessonQuestionOptions");

            migrationBuilder.DropTable(
                name: "LessonQuestions");

            migrationBuilder.DropTable(
                name: "Lessons");

            migrationBuilder.DropTable(
                name: "LessonCategories");
        }
    }
}
