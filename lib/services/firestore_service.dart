import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_sage/models/viaggio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get userId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Utente non autenticato');
    }
    return user.uid;
  }

  /// Salva un viaggio (creazione o aggiornamento)
  Future<void> saveViaggio(Viaggio viaggio) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('viaggi')
        .doc(viaggio.id);

    await docRef.set(viaggio.toJson());
  }

  /// Ottiene la lista completa dei viaggi (una tantum)
  Future<List<Viaggio>> getViaggi() async {
    final snapshot = await _db
      .collection('users')
      .doc(userId)
      .collection('viaggi')
      .get();

    print('📦 Docs in viaggi: ${snapshot.docs.length}');
    for (var doc in snapshot.docs) {
      print('📌 Doc id: ${doc.id}');
      print('📌 Doc data: ${doc.data()}');
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Assicurati che l'ID sia incluso nei dati
      return Viaggio.fromJson(data);
    }).toList();
  }

  /// Ottiene uno Stream in tempo reale dei viaggi
  Stream<List<Viaggio>> getViaggiStream() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('viaggi')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id; // Includi l'ID nel modello
              return Viaggio.fromJson(data);
            }).toList());
  }

  /// Elimina un viaggio
  Future<void> deleteViaggio(String viaggioId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('viaggi')
        .doc(viaggioId)
        .delete();
  }

  /// Metodo aggiuntivo per ottenere un singolo viaggio (utile per future estensioni)
  Future<Viaggio?> getViaggio(String viaggioId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('viaggi')
        .doc(viaggioId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Viaggio.fromJson(data);
    }
    return null;
  }
}
