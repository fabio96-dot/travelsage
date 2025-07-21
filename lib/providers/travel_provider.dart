import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_sage/models/viaggio.dart';
import '../../services/firestore_service.dart';


class TravelState {
  final List<Viaggio> viaggi;
  final bool isLoading;
  final String? errorMessage;

  TravelState({
    this.viaggi = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  TravelState copyWith({
    List<Viaggio>? viaggi,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TravelState(
      viaggi: viaggi ?? this.viaggi,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class TravelNotifier extends StateNotifier<TravelState> {
  final FirestoreService _firestoreService;
  StreamSubscription<List<Viaggio>>? _viaggiSubscription;
  bool _disposed = false; // Aggiungiamo un flag per tracciare lo stato

  TravelNotifier(this._firestoreService) : super(TravelState()) {
    _init();
  }

  Future<void> _init() async {
    await caricaViaggi();
    _setupFirestoreListener();
  }

  void _setupFirestoreListener() {
    _viaggiSubscription?.cancel();
    
    try {
      _viaggiSubscription = _firestoreService.getViaggiStream().listen(
        (viaggi) {
          if (!_disposed) { // Usiamo il nostro flag invece di isClosed
            state = state.copyWith(viaggi: viaggi, errorMessage: null);
          }
        },
        onError: (error) {
          if (!_disposed) {
            state = state.copyWith(
              errorMessage: 'Errore aggiornamento in tempo reale: $error',
            );
          }
        },
      );
    } catch (e) {
      print('❌ Errore inizializzazione listener: $e');
    }
  }

  Future<void> caricaViaggi() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final viaggi = await _firestoreService.getViaggi();
      if (!_disposed) {
        state = state.copyWith(viaggi: viaggi, isLoading: false);
      }
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Errore durante il caricamento: ${e.toString()}',
        );
      }
      rethrow;
    }
  }

  void aggiungiViaggioTemporaneo(Viaggio viaggio) {
    if (_disposed || state.viaggi.any((v) => v.id == viaggio.id)) return;
    state = state.copyWith(viaggi: [...state.viaggi, viaggio]);
  }

  Future<void> salvaViaggio(Viaggio viaggio) async {
    try {
      if (!state.viaggi.any((v) => v.id == viaggio.id)) {
        aggiungiViaggioTemporaneo(viaggio);
      }
      await _firestoreService.saveViaggio(viaggio);
    } catch (e) {
      await caricaViaggi();
      rethrow;
    }
  }

  Future<void> rimuoviViaggio(String id) async {
    try {
      state = state.copyWith(
        viaggi: state.viaggi.where((v) => v.id != id).toList(),
      );
      await _firestoreService.deleteViaggio(id);
    } catch (e) {
      await caricaViaggi();
      rethrow;
    }
  }

  Future<void> archiviaViaggiScaduti() async {
    try {
      state = state.copyWith(isLoading: true);
      final oggi = DateTime.now();
      
      for (final v in state.viaggi) {
        if (v.confermato && !v.archiviato && v.dataFine.isBefore(oggi)) {
          await _firestoreService.saveViaggio(v.copyWith(archiviato: true));
        }
      }
      
      if (!_disposed) {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(isLoading: false);
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _disposed = true; // Impostiamo il flag a true prima di cancellare
    _viaggiSubscription?.cancel();
    super.dispose();
  }
}
/// Provider per il notifier dei viaggi
final travelProvider = StateNotifierProvider<TravelNotifier, TravelState>((ref) {
  return TravelNotifier(FirestoreService());
});



