import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeocodingService {
  static Future<LatLng?> getCoordinates(String place) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('geo_$place');
    if (cached != null) {
      final data = json.decode(cached);
      return LatLng(data['lat'], data['lon']);
    }

    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$place&format=json&limit=1');
    final response = await http.get(url, headers: {'User-Agent': 'TravelSageApp'});
    if (response.statusCode == 200) {
      final results = json.decode(response.body);
      if (results.isNotEmpty) {
        final lat = double.parse(results[0]['lat']);
        final lon = double.parse(results[0]['lon']);
        prefs.setString('geo_$place', json.encode({'lat': lat, 'lon': lon}));
        return LatLng(lat, lon);
      }
    }
    return null;
  }
}

