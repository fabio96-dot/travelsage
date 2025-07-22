import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/viaggio.dart';

final unsplashApiProvider = Provider<UnsplashApi>((ref) {
  return UnsplashApi();
});

class UnsplashApi {
  static const _accessKey = 'Xj6hzaL43aNdBnzB_tYrsPdH4uB-EQ5dlDnFlF957VE';
  static const _baseUrl = 'https://api.unsplash.com';

  Future<String?> getImageForViaggio(Viaggio viaggio) async {
    // Controllo base su ID
    if (viaggio.id.isEmpty || viaggio.id.length < 10) {
      return null;
    }

    // Se immagine già presente, la uso direttamente
    if (viaggio.immagineUrl != null && viaggio.immagineUrl!.isNotEmpty) {
      return viaggio.immagineUrl;
    }

    final query = viaggio.destinazione;
    final url = Uri.parse('$_baseUrl/search/photos?query=$query&per_page=1&orientation=landscape');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Client-ID $_accessKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'];
        if (results != null && results.isNotEmpty) {
          final imageUrl = results[0]['urls']['regular'];

          final docRef = FirebaseFirestore.instance.collection('viaggi').doc(viaggio.id);

          // Verifico se documento esiste prima di aggiornare
          final docSnap = await docRef.get();
          if (docSnap.exists) {
            await docRef.update({'immagineUrl': imageUrl});
          }

          return imageUrl;
        }
      }
    } catch (e) {
      print('Errore Unsplash: $e');
    }

    return null;
  }
}
