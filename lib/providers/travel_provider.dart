import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_sage/models/viaggio.dart';
import '../../services/firestore_service.dart';

class TravelState {
  final List<Viaggio> viaggi;
  TravelState({this.viaggi = const []});

  TravelState copyWith({List<Viaggio>? viaggi}) {
    return TravelState(viaggi: viaggi ?? this.viaggi);
  }
}

class TravelNotifier extends StateNotifier<TravelState> {
  final FirestoreService _firestoreService;

  TravelNotifier(this._firestoreService) : super(TravelState()) {
    caricaViaggi();
  }

  /// Carica tutti i viaggi dell'utente autenticato e aggiorna lo stato
  Future<void> caricaViaggi() async {
    try {
      final viaggi = await _firestoreService.getViaggi();
      print('📦 Documenti ricevuti: ${viaggi.length}');
      for (var viaggio in viaggi) {
        print('📌 Viaggio: ${viaggio.titolo} dal ${viaggio.dataInizio}');
      }
      state = state.copyWith(viaggi: viaggi);
    } catch (e, stackTrace) {
      print('❌ Errore durante il caricamento dei viaggi: $e');
      print(stackTrace);
    }
  }

  /// Salva un viaggio (nuovo o aggiornamento)
  Future<void> salvaViaggio(Viaggio viaggio) async {
    try {
      await _firestoreService.saveViaggio(viaggio);
      final listaAggiornata = [
        for (final v in state.viaggi)
          if (v.id != viaggio.id) v,
        viaggio,
      ];
      state = state.copyWith(viaggi: listaAggiornata);
    } catch (e) {
      print('❌ Errore salvataggio viaggio: $e');
      throw Exception('Errore salvataggio viaggio: $e');
    }
  }

  /// Rimuove viaggio da Firestore e stato locale
  Future<void> rimuoviViaggio(String id) async {
    try {
      await _firestoreService.deleteViaggio(id);
      final listaAggiornata = state.viaggi.where((v) => v.id != id).toList();
      state = state.copyWith(viaggi: listaAggiornata);
    } catch (e) {
      print('❌ Errore eliminazione viaggio: $e');
      throw Exception('Errore eliminazione viaggio: $e');
    }
  }

  /// Archivia tutti i viaggi confermati e scaduti (dataFine < oggi)
  Future<void> archiviaViaggiScaduti() async {
    final oggi = DateTime.now();
    final aggiornati = <Viaggio>[];

    for (final v in state.viaggi) {
      if (v.confermato && !v.archiviato && v.dataFine.isBefore(oggi)) {
        final viaggModificato = v.copyWith(archiviato: true);
        await _firestoreService.saveViaggio(viaggModificato);
        aggiornati.add(viaggModificato);
      } else {
        aggiornati.add(v);
      }
    }

    state = state.copyWith(viaggi: aggiornati);
  }
}

// Provider per TravelNotifier, passando FirestoreService con userId dinamico
final travelProvider = StateNotifierProvider<TravelNotifier, TravelState>((ref) {
  final firestoreService = FirestoreService();
  return TravelNotifier(firestoreService);
});




