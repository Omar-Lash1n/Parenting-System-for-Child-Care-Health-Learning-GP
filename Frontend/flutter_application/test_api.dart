import 'package:http/http.dart' as http;
void main() async {
  try {
    var res = await http.get(Uri.parse('https://ajial-api-dev-dvg9hfgtdgewekcv.westeurope-01.azurewebsites.net/api/parent/consultations/specialties'));
    print('STATUS: ${res.statusCode}');
    print('BODY: ${res.body}');
  } catch (e) {
    print('ERROR: $e');
  }
}
