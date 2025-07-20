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

  Future<void> saveViaggio(Viaggio viaggio) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('viaggi')
        .doc(viaggio.id);

    await docRef.set(viaggio.toJson());
  }

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
      data['id'] = doc.id;
      return Viaggio.fromJson(data);
    }).toList();
  }

  Future<void> deleteViaggio(String viaggioId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('viaggi')
        .doc(viaggioId)
        .delete();
  }
}
