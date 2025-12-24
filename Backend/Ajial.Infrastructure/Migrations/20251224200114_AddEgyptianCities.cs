using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace Ajial.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddEgyptianCities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.InsertData(
                table: "Cities",
                columns: new[] { "Id", "IsActive", "Name", "NameAr" },
                values: new object[,]
                {
                    { 6, true, "Suez", "السويس" },
                    { 7, true, "Mansoura", "المنصورة" },
                    { 8, true, "El Mahalla El Kubra", "المحلة الكبرى" },
                    { 9, true, "Tanta", "طنطا" },
                    { 10, true, "Asyut", "أسيوط" },
                    { 11, true, "Fayyum", "الفيوم" },
                    { 12, true, "Zagazig", "الزقازيق" },
                    { 13, true, "Ismailia", "الإسماعيلية" },
                    { 14, true, "Aswan", "أسوان" },
                    { 15, true, "6th of October City", "السادس من أكتوبر" },
                    { 16, true, "Damanhur", "دمنهور" },
                    { 17, true, "Damietta", "دمياط" },
                    { 18, true, "Minya", "المنيا" },
                    { 19, true, "Beni Suef", "بني سويف" },
                    { 20, true, "Luxor", "الأقصر" },
                    { 21, true, "Sohag", "سوهاج" },
                    { 22, true, "Shibin El Kom", "شبين الكوم" },
                    { 23, true, "Qena", "قنا" },
                    { 24, true, "Hurghada", "الغردقة" },
                    { 25, true, "Arish", "العريش" },
                    { 26, true, "Mallawi", "ملوي" },
                    { 27, true, "10th of Ramadan City", "العاشر من رمضان" },
                    { 28, true, "Bilbais", "بلبيس" },
                    { 29, true, "Marsa Matruh", "مرسى مطروح" },
                    { 30, true, "Banha", "بنها" },
                    { 31, true, "Kafr El Sheikh", "كفر الشيخ" },
                    { 32, true, "Sharm El Sheikh", "شرم الشيخ" },
                    { 33, true, "New Cairo", "القاهرة الجديدة" },
                    { 34, true, "New Administrative Capital", "العاصمة الإدارية الجديدة" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 6);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 7);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 8);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 9);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 10);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 11);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 12);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 13);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 14);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 15);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 16);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 17);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 18);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 19);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 20);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 21);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 22);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 23);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 24);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 25);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 26);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 27);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 28);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 29);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 30);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 31);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 32);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 33);

            migrationBuilder.DeleteData(
                table: "Cities",
                keyColumn: "Id",
                keyValue: 34);
        }
    }
}
