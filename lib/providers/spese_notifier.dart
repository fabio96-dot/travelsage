import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_sage/models/spesa.dart';

final speseProvider = StateNotifierProvider.family<SpeseNotifier, List<Spesa>, String>((ref, viaggioId) {
  final notifier = SpeseNotifier();
  notifier.loadSpese(viaggioId);
  return notifier;
});

class SpeseNotifier extends StateNotifier<List<Spesa>> {
  SpeseNotifier(): super([]);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> loadSpese(String viaggioId) async {
    final snapshot = await _firestore.collection('viaggi')
      .doc(viaggioId)
      .collection('spese')
      .get();

    final speseList = snapshot.docs.map((doc) => Spesa.fromJson(doc.data())).toList();
    state = speseList;
  }

  Future<void> aggiungiSpesa(String viaggioId, Spesa nuovaSpesa) async {
    final speseRef = _firestore.collection('viaggi').doc(viaggioId).collection('spese');
    await speseRef.doc(nuovaSpesa.id).set(nuovaSpesa.toJson());
    state = [...state, nuovaSpesa];
  }

  Future<void> modificaSpesa(String viaggioId, Spesa spesaModificata) async {
    final speseRef = _firestore.collection('viaggi').doc(viaggioId).collection('spese');
    await speseRef.doc(spesaModificata.id).set(spesaModificata.toJson());
    state = [
      for (final spesa in state)
        if (spesa.id == spesaModificata.id) spesaModificata else spesa,
    ];
  }

  Future<void> eliminaSpesa(String viaggioId, String spesaId) async {
    final speseRef = _firestore.collection('viaggi').doc(viaggioId).collection('spese');
    await speseRef.doc(spesaId).delete();
    state = state.where((spesa) => spesa.id != spesaId).toList();
  }
}
