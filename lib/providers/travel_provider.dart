import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_sage/models/viaggio.dart';
import '../../services/firestore_service.dart';
import '../utils/helpers/hive_istances.dart';
import '../utils/viaggio_type_adapter.dart'; // ✅ Per HiveViaggio
import 'package:connectivity_plus/connectivity_plus.dart';


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
    await _caricaDaHive(); // ✅ Carica subito da Hive
    final connessione = await Connectivity().checkConnectivity();
    if (connessione != ConnectivityResult.none) {
      await caricaViaggi(); // ✅ Poi sincronizza se online
      _setupFirestoreListener();
    }
  }

  Future<void> _caricaDaHive() async {
    try {
      final hiveItems = await viaggiHelper.getAll();
      final viaggiConvertiti = hiveItems
          .whereType<HiveViaggio>()
          .map((h) => h.toModel("default")) // 🔁 userId temporaneo
          .toList();
      if (!_disposed) {
        state = state.copyWith(viaggi: viaggiConvertiti, isLoading: false);
      }
    } catch (e) {
      print('❌ Errore caricamento Hive: $e');
    }
  }


  void _setupFirestoreListener() {
    _viaggiSubscription?.cancel();
    
    try {
      _viaggiSubscription = _firestoreService.getViaggiStream().listen(
        (viaggi) async {
          if (!_disposed) {
            state = state.copyWith(viaggi: viaggi, errorMessage: null);
            // 🔁 Salva anche su Hive
            await viaggiHelper.clearAll();
            for (final v in viaggi) {
              await viaggiHelper.save(v.id, HiveViaggio.fromModel(v));
            }
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
      final oggi = DateTime.now();
      final oggiSoloData = DateTime(oggi.year, oggi.month, oggi.day);

      bool modificato = false;

      for (final v in state.viaggi) {
          
          print('🕓 Controllo viaggio: ${v.titolo}');
          print('• dataFine: ${v.dataFine}');
          print('• confermato: ${v.confermato}');
          print('• archiviato: ${v.archiviato}');

        final DaArchiviare = v.confermato && !v.archiviato && v.dataFine.isBefore(oggiSoloData);
        if (DaArchiviare) {
          final aggiornato = v.copyWith(archiviato: true);
          await _firestoreService.saveViaggio(aggiornato);
          modificato = true;
        }
      }

      if (modificato) {
        print('🔄 Viaggi archiviati. Ricarico da Firestore...');
        await caricaViaggi();
      } else {
        print('ℹ️ Nessun viaggio da archiviare.');
      }

    } catch (e) {
      print('❌ Errore archiviazione: $e');
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



