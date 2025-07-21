import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class UnsplashApi {
  static const _accessKey = 'Xj6hzaL43aNdBnzB_tYrsPdH4uB-EQ5dlDnFlF957VE';
  static const _baseUrl = 'https://api.unsplash.com';

  static Future<String?> getImmagineViaggio({required String viaggioId, required String destinazione}) async {
    final docRef = FirebaseFirestore.instance.collection('viaggi').doc(viaggioId);
    final doc = await docRef.get();

    // 1. Se ha già l'immagine, restituiscila
    if (doc.exists && doc.data()?['immagineUrl'] != null) {
      return doc.data()?['immagineUrl'] as String;
    }

    // 2. Altrimenti, cerca l’immagine su Unsplash
    final imageUrl = await _cercaFoto(destinazione);
    if (imageUrl != null) {
      // 3. Salva nel documento per caching futuro
      await docRef.update({'immagineUrl': imageUrl});
    }

    return imageUrl;
  }

  static Future<String?> _cercaFoto(String query) async {
    final url = Uri.parse('$_baseUrl/search/photos?query=$query&orientation=landscape&per_page=1');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Client-ID $_accessKey'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'];
      if (results != null && results.isNotEmpty) {
        return results[0]['urls']['regular'];
      }
    }
    return null;
  }
}
