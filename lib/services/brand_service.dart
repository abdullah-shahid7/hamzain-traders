import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hamzain_traders/models/brand.dart';

class BrandService {
  static const String _endpoint =
      'https://devtechnical.com/Abdullah.Shahid/HamZainTraders/getbrands.php';

  Future<List<Brand>> fetchBrands() async {
    final response = await http
        .get(Uri.parse(_endpoint))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data
          .map((item) => Brand.fromJson(item as Map<String, dynamic>))
          .where((brand) => brand.status == '1')
          .toList();
    }

    throw Exception('Failed to load brands (${response.statusCode})');
  }
}
