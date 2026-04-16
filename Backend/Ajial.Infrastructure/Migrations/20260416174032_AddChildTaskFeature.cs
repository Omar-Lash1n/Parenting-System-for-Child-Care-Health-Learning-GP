using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddChildTaskFeature : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ChildTasks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ParentId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    Title = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    TaskImageUrl = table.Column<string>(type: "nvarchar(2048)", maxLength: 2048, nullable: true),
                    RecordingUrl = table.Column<string>(type: "nvarchar(2048)", maxLength: 2048, nullable: true),
                    RecordingDurationSeconds = table.Column<int>(type: "int", nullable: true),
                    Stars = table.Column<int>(type: "int", nullable: false, defaultValue: 0),
                    StartDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    DueDate = table.Column<DateTime>(type: "datetime2", nullable: true),
                    IsCompletedByParent = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    CompletedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChildTasks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChildTasks_Parents_ParentId",
                        column: x => x.ParentId,
                        principalTable: "Parents",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ChildTaskAssignees",
                columns: table => new
                {
                    TaskId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ChildId = table.Column<Guid>(type: "uniqueidentifier", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChildTaskAssignees", x => new { x.TaskId, x.ChildId });
                    table.ForeignKey(
                        name: "FK_ChildTaskAssignees_ChildTasks_TaskId",
                        column: x => x.TaskId,
                        principalTable: "ChildTasks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ChildTaskAssignees_Children_ChildId",
                        column: x => x.ChildId,
                        principalTable: "Children",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "ChildTaskRecurrences",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    TaskId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    IsRecurring = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    RepeatDays = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: true),
                    RepeatTime = table.Column<string>(type: "nvarchar(5)", maxLength: 5, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChildTaskRecurrences", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChildTaskRecurrences_ChildTasks_TaskId",
                        column: x => x.TaskId,
                        principalTable: "ChildTasks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ChildTaskAssignees_ChildId",
                table: "ChildTaskAssignees",
                column: "ChildId");

            migrationBuilder.CreateIndex(
                name: "IX_ChildTaskAssignees_TaskId",
                table: "ChildTaskAssignees",
                column: "TaskId");

            migrationBuilder.CreateIndex(
                name: "IX_ChildTaskRecurrences_TaskId",
                table: "ChildTaskRecurrences",
                column: "TaskId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ChildTasks_DueDate",
                table: "ChildTasks",
                column: "DueDate");

            migrationBuilder.CreateIndex(
                name: "IX_ChildTasks_IsCompletedByParent",
                table: "ChildTasks",
                column: "IsCompletedByParent");

            migrationBuilder.CreateIndex(
                name: "IX_ChildTasks_ParentId",
                table: "ChildTasks",
                column: "ParentId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ChildTaskAssignees");

            migrationBuilder.DropTable(
                name: "ChildTaskRecurrences");

            migrationBuilder.DropTable(
                name: "ChildTasks");
        }
    }
}
