import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prenotazione.dart';

final prenotazioniProvider = StreamProvider.family<List<Prenotazione>, ({String userId, String viaggioId})>((ref, args) {
  return FirebaseFirestore.instance
      .collection('viaggi')
      .doc(args.viaggioId)
      .collection('prenotazioni')
      .orderBy('data')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Prenotazione.fromFirestore(doc)).toList());
});

final prenotazioneNotifierProvider = StateNotifierProvider<PrenotazioneNotifier, List<Prenotazione>>(
  (ref) => PrenotazioneNotifier(),
);

class PrenotazioneNotifier extends StateNotifier<List<Prenotazione>> {
  final _firestore = FirebaseFirestore.instance;

  PrenotazioneNotifier() : super([]);

  Future<void> aggiungiPrenotazione({
    required String viaggioId,
    required Prenotazione prenotazione,
  }) async {
    final docRef = _firestore
        .collection('viaggi')
        .doc(viaggioId)
        .collection('prenotazioni')
        .doc(prenotazione.id);

    await docRef.set(prenotazione.toMap());
    // Aggiorna lo stato localmente aggiungendo la nuova prenotazione
    state = [...state, prenotazione];
  }

  Future<void> eliminaPrenotazione({
    required String viaggioId,
    required String prenotazioneId,
  }) async {
    await _firestore
        .collection('viaggi')
        .doc(viaggioId)
        .collection('prenotazioni')
        .doc(prenotazioneId)
        .delete();

    // Aggiorna lo stato rimuovendo la prenotazione cancellata
    state = state.where((p) => p.id != prenotazioneId).toList();
  }

  Future<void> modificaPrenotazione({
    required String viaggioId,
    required Prenotazione prenotazione,
  }) async {
    final docRef = _firestore
        .collection('viaggi')
        .doc(viaggioId)
        .collection('prenotazioni')
        .doc(prenotazione.id);

    await docRef.set(prenotazione.toMap(), SetOptions(merge: true));

    // Aggiorna lo stato modificando la prenotazione
    state = [
      for (final p in state)
        if (p.id == prenotazione.id) prenotazione else p,
    ];
  }
}

