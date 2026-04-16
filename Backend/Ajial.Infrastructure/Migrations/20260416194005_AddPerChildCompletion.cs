using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddPerChildCompletion : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_ChildTasks_IsCompletedByParent",
                table: "ChildTasks");

            migrationBuilder.DropColumn(
                name: "CompletedAt",
                table: "ChildTasks");

            migrationBuilder.DropColumn(
                name: "IsCompletedByParent",
                table: "ChildTasks");

            migrationBuilder.DropColumn(
                name: "RecordingDurationSeconds",
                table: "ChildTasks");

            migrationBuilder.AddColumn<DateTime>(
                name: "CompletedAt",
                table: "ChildTaskAssignees",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsCompleted",
                table: "ChildTaskAssignees",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateIndex(
                name: "IX_ChildTaskAssignees_ChildId_IsCompleted",
                table: "ChildTaskAssignees",
                columns: new[] { "ChildId", "IsCompleted" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_ChildTaskAssignees_ChildId_IsCompleted",
                table: "ChildTaskAssignees");

            migrationBuilder.DropColumn(
                name: "CompletedAt",
                table: "ChildTaskAssignees");

            migrationBuilder.DropColumn(
                name: "IsCompleted",
                table: "ChildTaskAssignees");

            migrationBuilder.AddColumn<DateTime>(
                name: "CompletedAt",
                table: "ChildTasks",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsCompletedByParent",
                table: "ChildTasks",
                type: "bit",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<int>(
                name: "RecordingDurationSeconds",
                table: "ChildTasks",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_ChildTasks_IsCompletedByParent",
                table: "ChildTasks",
                column: "IsCompletedByParent");
        }
    }
}
