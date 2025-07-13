import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_sage/models/viaggio.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Per ora usiamo un utente statico
  final String userId = 'defaultUser';

  /// Salva o aggiorna un viaggio (compreso itinerario e spese)
  Future<void> saveViaggio(Viaggio viaggio) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('viaggi')
        .doc(viaggio.id);

    await docRef.set(viaggio.toJson());
  }

  /// Carica tutti i viaggi dell'utente
  Future<List<Viaggio>> getViaggi() async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('viaggi')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;  // assegna l'id del documento
      return Viaggio.fromJson(data);
    }).toList();
  }

  /// Elimina un viaggio (opzionale)
  Future<void> deleteViaggio(String viaggioId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('viaggi')
        .doc(viaggioId)
        .delete();
  }
}
