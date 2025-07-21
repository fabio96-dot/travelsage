import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/viaggio.dart';

class AttivitaNotifier extends StateNotifier<AsyncValue<void>> {
  AttivitaNotifier() : super(const AsyncData(null));

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> aggiungiAttivita({
    required String userId,
    required String viaggioId,
    required Attivita attivita,
  }) async {
    state = const AsyncLoading();
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('viaggi')
          .doc(viaggioId)
          .collection('attivita')
          .doc(attivita.id); // usa id univoco di Attivita

      await docRef.set(attivita.toJson());
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> modificaAttivita({
    required String userId,
    required String viaggioId,
    required Attivita attivita,
  }) async {
    state = const AsyncLoading();
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('viaggi')
          .doc(viaggioId)
          .collection('attivita')
          .doc(attivita.id);

      await docRef.update(attivita.toJson());
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> rimuoviAttivita({
    required String userId,
    required String viaggioId,
    required Attivita attivita,
  }) async {
    state = const AsyncLoading();
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('viaggi')
          .doc(viaggioId)
          .collection('attivita')
          .doc(attivita.id);

      await docRef.delete();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

// Provider per il notifier
final attivitaNotifierProvider = StateNotifierProvider<AttivitaNotifier, AsyncValue<void>>(
  (ref) => AttivitaNotifier(),
);
