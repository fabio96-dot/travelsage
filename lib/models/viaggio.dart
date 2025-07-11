import 'package:intl/intl.dart';
import 'spesa.dart';

class Viaggio {
  final String id;
  final String titolo;
  final String destinazione;
  final DateTime dataInizio;
  final DateTime dataFine;
  final String budget;
  final List<String> partecipanti;
  final bool confermato;
  final List<Spesa> spese;
  final bool archiviato;
  final String? note;
  final Map<String, List<Attivita>> itinerario;

  Viaggio({
    required this.id,
    required this.titolo,
    required this.destinazione,
    required this.dataInizio,
    required this.dataFine,
    required this.budget,
    required this.partecipanti,
    this.confermato = false,
    this.spese = const [],
    this.archiviato = false,
    this.note,
    Map<String, List<Attivita>>? itinerario,
  }) : itinerario = itinerario ?? {};

  // Metodo copiaConSpese aggiornato
  Viaggio copiaConSpese(List<Spesa> nuoveSpese) {
    return Viaggio(
      id: id,
      titolo: titolo,
      destinazione: destinazione,
      dataInizio: dataInizio,
      dataFine: dataFine,
      budget: budget,
      partecipanti: partecipanti,
      confermato: confermato,
      spese: nuoveSpese,
      archiviato: archiviato,
      note: note,
      itinerario: Map.from(itinerario),
    );
  }

  // Metodo copyWith completo
  Viaggio copyWith({
    String? id,
    String? titolo,
    String? destinazione,
    DateTime? dataInizio,
    DateTime? dataFine,
    String? budget,
    List<String>? partecipanti,
    bool? confermato,
    List<Spesa>? spese,
    bool? archiviato,
    String? note,
    Map<String, List<Attivita>>? itinerario,
  }) {
    return Viaggio(
      id: id ?? this.id,
      titolo: titolo ?? this.titolo,
      destinazione: destinazione ?? this.destinazione,
      dataInizio: dataInizio ?? this.dataInizio,
      dataFine: dataFine ?? this.dataFine,
      budget: budget ?? this.budget,
      partecipanti: partecipanti ?? this.partecipanti,
      confermato: confermato ?? this.confermato,
      spese: spese ?? this.spese,
      archiviato: archiviato ?? this.archiviato,
      note: note ?? this.note,
      itinerario: itinerario ?? Map.from(this.itinerario),
    );
  }

  // Calcola il totale delle spese
  double get totaleSpese {
    return spese.fold(0, (sum, spesa) => sum + spesa.importo);
  }

  // Calcola le spese per partecipante
  Map<String, double> get spesePerPartecipante {
    final map = <String, double>{};
    for (final partecipante in partecipanti) {
      map[partecipante] = spese
          .where((s) => s.pagatore == partecipante)
          .fold(0, (sum, spesa) => sum + spesa.importo);
    }
    return map;
  }

  // Calcola la quota equa per partecipante
  double get quotaEqua {
    return partecipanti.isEmpty ? 0 : totaleSpese / partecipanti.length;
  }

  // Metodi per gestire l'itinerario

  void aggiungiAttivita(DateTime giorno, Attivita attivita) {
  final key = _formatDayKey(giorno);
  itinerario[key] = [...itinerario[key] ?? [], attivita];
}


  void modificaAttivita(DateTime giorno, String attivitaId, Attivita nuovaAttivita) {
  final key = _formatDayKey(giorno);
  final attivitaGiorno = itinerario[key];
  if (attivitaGiorno != null) {
    final index = attivitaGiorno.indexWhere((a) => a.id == attivitaId);
    if (index != -1) {
      attivitaGiorno[index] = nuovaAttivita;
    }
  }
}

  void rimuoviAttivita(DateTime giorno, String attivitaId) {
  final key = _formatDayKey(giorno);
  itinerario[key]?.removeWhere((a) => a.id == attivitaId);
  if (itinerario[key]?.isEmpty ?? false) {
    itinerario.remove(key);
  }
}

  List<Attivita>? attivitaDelGiorno(DateTime giorno) {
    return itinerario[_formatDayKey(giorno)];
  }

  String _formatDayKey(DateTime giorno) {
    return DateFormat('yyyy-MM-dd').format(giorno);
  }

  // Metodi per serializzazione
  factory Viaggio.fromJson(Map<String, dynamic> json) {
    return Viaggio(
      id: json['id'],
      titolo: json['titolo'],
      destinazione: json['destinazione'],
      dataInizio: DateTime.parse(json['dataInizio']),
      dataFine: DateTime.parse(json['dataFine']),
      budget: json['budget'] ?? '',
      partecipanti: List<String>.from(json['partecipanti'] ?? []),
      confermato: json['confermato'] ?? false,
      spese: (json['spese'] as List<dynamic>?)
              ?.map((s) => Spesa.fromJson(s))
              .toList() ??
          [],
      archiviato: json['archiviato'] ?? false,
      note: json['note'],
      itinerario: json['itinerario'] != null
          ? (json['itinerario'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                key,
                (value as List).map((a) => Attivita.fromJson(a)).toList(),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titolo': titolo,
      'destinazione': destinazione,
      'dataInizio': dataInizio.toIso8601String(),
      'dataFine': dataFine.toIso8601String(),
      'budget': budget,
      'partecipanti': partecipanti,
      'confermato': confermato,
      'spese': spese.map((s) => s.toJson()).toList(),
      'archiviato': archiviato,
      'note': note,
      'itinerario': itinerario.map(
        (key, value) => MapEntry(
          key,
          value.map((a) => a.toJson()).toList(),
        ),
      ),
    };
  }
}

class Attivita {
  final String id;
  String titolo;
  String descrizione;
  DateTime orario;
  String? luogo;
  bool completata;

  Attivita({
    required this.id,
    required this.titolo,
    required this.descrizione,
    required this.orario,
    this.luogo,
    this.completata = false,
  });

  factory Attivita.fromJson(Map<String, dynamic> json) {
    return Attivita(
      id: json['id'],
      titolo: json['titolo'],
      descrizione: json['descrizione'],
      orario: DateTime.parse(json['orario']),
      luogo: json['luogo'],
      completata: json['completata'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titolo': titolo,
      'descrizione': descrizione,
      'orario': orario.toIso8601String(),
      'luogo': luogo,
      'completata': completata,
    };
  }
}