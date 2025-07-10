import 'spesa.dart';

class Viaggio {
  final String destinazione;
  final DateTime dataInizio; // CAMBIATO
  final DateTime dataFine;   // CAMBIATO
  final String budget;
  final List<String> partecipanti;
  final bool confermato;
  final List<Spesa> spese;
  final bool archiviato;  // nuova proprietà

  Viaggio({
    required this.destinazione,
    required this.dataInizio,
    required this.dataFine,
    required this.budget,
    required this.partecipanti,
    this.confermato = false,
    this.spese = const [], // default vuoto
    this.archiviato = false, // default false
  });

  Viaggio copiaConSpese(List<Spesa> nuoveSpese) {
    return Viaggio(
      destinazione: destinazione,
      dataInizio: dataInizio,
      dataFine: dataFine,
      budget: budget,
      partecipanti: partecipanti,
      confermato: confermato,
      spese: nuoveSpese,
      archiviato: archiviato,
    );
  }

  // Metodo copyWith per aggiornamenti parziali più comodi
  Viaggio copyWith({
    String? destinazione,
    DateTime? dataInizio, // CAMBIATO
    DateTime? dataFine,   // CAMBIATO
    String? budget,
    List<String>? partecipanti,
    bool? confermato,
    List<Spesa>? spese,
    bool? archiviato,
  }) {
    return Viaggio(
      destinazione: destinazione ?? this.destinazione,
      dataInizio: dataInizio ?? this.dataInizio,
      dataFine: dataFine ?? this.dataFine,
      budget: budget ?? this.budget,
      partecipanti: partecipanti ?? this.partecipanti,
      confermato: confermato ?? this.confermato,
      spese: spese ?? this.spese,
      archiviato: archiviato ?? this.archiviato,
    );
  }
}
