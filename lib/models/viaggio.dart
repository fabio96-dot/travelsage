import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'spesa.dart';

class Viaggio {
  final String userId;
  final String id;
  final String titolo;
  final String partenza;
  final String destinazione;
  final DateTime dataInizio;
  final DateTime dataFine;
  final String budget;
  final List<String> partecipanti;
  final bool confermato;
  final List<Spesa> spese;
  final bool archiviato;
  final String? note;
  Map<String, List<Attivita>> itinerario;
  final List<String> interessi;
  final String mezzoTrasporto; // Nuovo campo per mezzo di trasporto
  final int attivitaGiornaliere; // Numero di attività giornaliere
  final double raggioKm; // Raggio massimo in km
  final double etaMedia; // Età media dei partecipanti
  final String tipologiaViaggiatore; // Tipologia del viaggiatore
  final String? immagineUrl;

  Viaggio({
    required this.userId,
    required this.id,
    required this.titolo,
    required this.partenza,
    required this.destinazione,
    required this.dataInizio,
    required this.dataFine,
    required this.budget,
    required this.partecipanti,
    this.confermato = false,
    this.spese = const [],
    this.archiviato = false,
    this.note,
    this.interessi = const [], // 👈 nuovo campo
    this.mezzoTrasporto = 'Aereo', // 👈 nuovo campo con valore di default
    this.attivitaGiornaliere = 3, // 👈 nuovo campo con valore di default
    this.raggioKm = 100.0, // 👈 nuovo campo con valore di default
    this.etaMedia = 30.0, // 👈 nuovo campo con valore di default
    this.tipologiaViaggiatore = 'Backpacker', // 👈 nuovo campo con valore di default
    this.immagineUrl,
    Map<String, List<Attivita>>? itinerario,
  }) : itinerario = itinerario ?? {};

  // Metodo copiaConSpese aggiornato
  Viaggio copiaConSpese(List<Spesa> nuoveSpese) {
    return Viaggio(
      userId: userId,
      id: id,
      titolo: titolo,
      partenza: partenza,
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
      interessi: List.from(interessi), // 👈 copia della lista degli interessi
      mezzoTrasporto: mezzoTrasporto, // 👈 copia del mezzo di trasporto
      attivitaGiornaliere: attivitaGiornaliere, // 👈 copia del numero di attività giornaliere
      raggioKm: raggioKm, // 👈 copia del raggio massimo
      etaMedia: etaMedia, // 👈 copia dell'età media
      tipologiaViaggiatore: tipologiaViaggiatore, // 👈 copia della tipologia del viaggiatore
      immagineUrl: immagineUrl, // 👈 copia dell'URL dell'immagine
    );
  }

  // Metodo copyWith completo
  Viaggio copyWith({
    String? userId,
    String? id,
    String? titolo,
    String? partenza,
    String? destinazione,
    DateTime? dataInizio,
    DateTime? dataFine,
    String? budget,
    List<String>? partecipanti,
    bool? confermato,
    List<Spesa>? spese,
    bool? archiviato,
    String? note,
    List<String>? interessi, // 👈 nuovo parametro
    String? mezzoTrasporto, // 👈 nuovo parametro
    int? attivitaGiornaliere, // 👈 nuovo parametro
    double? raggioKm, // 👈 nuovo parametro
    double? etaMedia, // 👈 nuovo parametro
    String? tipologiaViaggiatore, // 👈 nuovo parametro
    Map<String, List<Attivita>>? itinerario,
    String? immagineUrl, // 👈 nuovo parametro per l'immagine
  }) {
    return Viaggio(
      userId: userId ?? this.userId,  
      id: id ?? this.id,
      titolo: titolo ?? this.titolo,
      partenza: partenza ?? this.partenza,
      destinazione: destinazione ?? this.destinazione,
      dataInizio: dataInizio ?? this.dataInizio,
      dataFine: dataFine ?? this.dataFine,
      budget: budget ?? this.budget,
      partecipanti: partecipanti ?? this.partecipanti,
      confermato: confermato ?? this.confermato,
      spese: spese ?? this.spese,
      archiviato: archiviato ?? this.archiviato,
      note: note ?? this.note,
      interessi: interessi ?? this.interessi, // 👈
      itinerario: itinerario ?? Map.from(this.itinerario),
      mezzoTrasporto: mezzoTrasporto ?? this.mezzoTrasporto, // 👈
      attivitaGiornaliere: attivitaGiornaliere ?? this.attivitaGiornaliere, // 👈
      raggioKm: raggioKm ?? this.raggioKm, // 👈
      etaMedia: etaMedia ?? this.etaMedia, // 👈
      tipologiaViaggiatore: tipologiaViaggiatore ?? this.tipologiaViaggiatore, // 👈
      immagineUrl: immagineUrl ?? this.immagineUrl, // 👈
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
    final key = _formatDayKey(DateTime(giorno.year, giorno.month, giorno.day));
    return itinerario[key];
  }

  String _formatDayKey(DateTime giorno) {
    return DateFormat('yyyy-MM-dd').format(giorno);
  }

  // Metodi per serializzazione
  factory Viaggio.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now(); // fallback
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now(); // fallback
    }

    int _parseInt(dynamic value, int defaultValue) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
    }

   double _parseDouble(dynamic value, double defaultValue) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
    }

    return Viaggio(
    userId: json['userId']?.toString() ?? '',  
    id: json['id']?.toString() ?? '',
    titolo: json['titolo']?.toString() ?? '',
    partenza: json['partenza']?.toString() ?? '',
    destinazione: json['destinazione']?.toString() ?? '',
    dataInizio: _parseDate(json['dataInizio']),
    dataFine: _parseDate(json['dataFine']),
    budget: json['budget']?.toString() ?? '',
    partecipanti: json['partecipanti'] is List ? List<String>.from(json['partecipanti']) : [],
    confermato: json['confermato'] ?? false,
    spese: (json['spese'] as List<dynamic>?)?.map((s) => Spesa.fromJson(s)).toList() ?? [],
    archiviato: json['archiviato'] ?? false,
    note: json['note']?.toString(),
    interessi: json['interessi'] is List ? List<String>.from(json['interessi']) : [],
    mezzoTrasporto: json['mezzoTrasporto']?.toString() ?? 'Aereo',
    attivitaGiornaliere: _parseInt(json['attivitaGiornaliere'], 3),
    raggioKm: _parseDouble(json['raggioKm'], 100.0),
    etaMedia: _parseDouble(json['etaMedia'], 30.0),
    tipologiaViaggiatore: json['tipologiaViaggiatore']?.toString() ?? 'Backpacker',
    immagineUrl: json['immagineUrl']?.toString(),    itinerario: json['itinerario'] != null
        ? (json['itinerario'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(
              key,
              (value as List).map((a) => Attivita.fromJson(a)).toList(),
            ),
          )
        : {},
    );
  }



  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'id': id,
      'titolo': titolo,
      'partenza': partenza,
      'destinazione': destinazione,
      'dataInizio': Timestamp.fromDate(dataInizio),
      'dataFine': Timestamp.fromDate(dataFine),
      'budget': budget,
      'partecipanti': partecipanti,
      'confermato': confermato,
      'spese': spese.map((s) => s.toJson()).toList(),
      'archiviato': archiviato,
      'note': note,
      'interessi': interessi,
      'mezzoTrasporto': mezzoTrasporto, // 👈 nuovo campo
      'attivitaGiornaliere': attivitaGiornaliere, // 👈 nuovo campo
      'raggioKm': raggioKm, // 👈 nuovo campo
      'etaMedia': etaMedia, // 👈 nuovo campo
      'tipologiaViaggiatore': tipologiaViaggiatore, // 👈 nuovo campo
      'immagineUrl': immagineUrl, // 👈 nuovo campo per l'immagine
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
  bool generataDaIA;
  String categoria; // attività, trasporto, pernottamento
  final double? costoStimato;

  // Nuovi campi
  String? emozioni;      // pensieri / emozioni dell'utente
  String? immaginePath;  // percorso o URL immagine associata

  // Nuovo campo giorno in formato stringa yyyy-MM-dd
  late final String giorno;

  Attivita({
    required this.id,
    required this.titolo,
    required this.descrizione,
    required this.orario,
    this.luogo,
    this.completata = false,
    this.generataDaIA = false,
    this.categoria = 'attivita',
    this.costoStimato = 0.0,
    this.emozioni,
    this.immaginePath,
  }) {
    // Imposta giorno ogni volta che crei l'oggetto
    giorno = DateFormat('yyyy-MM-dd').format(orario);
  }

  factory Attivita.fromJson(Map<String, dynamic> json) {
    final dynamic orarioRaw = json['orario'];

    DateTime orarioParsed;
    if (orarioRaw is Timestamp) {
      orarioParsed = orarioRaw.toDate();
    } else if (orarioRaw is String) {
      orarioParsed = DateTime.tryParse(orarioRaw) ?? DateTime.now();
    } else {
      orarioParsed = DateTime.now();
    }

    final attivita = Attivita(
      id: json['id'] ?? '',
      titolo: json['titolo'] ?? '',
      descrizione: json['descrizione'] ?? '',
      orario: orarioParsed,
      luogo: json['luogo'],
      completata: json['completata'] ?? false,
      generataDaIA: json['generataDaIA'] ?? false,
      categoria: json['categoria'] ?? 'attivita',
      costoStimato: (json['costoStimato'] ?? 0).toDouble(),
      emozioni: json['emozioni'],
      immaginePath: json['immaginePath'],
    );

    return attivita;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titolo': titolo,
      'descrizione': descrizione,
      'orario': Timestamp.fromDate(orario),
      'luogo': luogo,
      'completata': completata,
      'generataDaIA': generataDaIA,
      'categoria': categoria,
      'costoStimato': costoStimato,
      'emozioni': emozioni,
      'immaginePath': immaginePath,
      'giorno': giorno,  // <-- salva il campo giorno in Firestore
    };
  }

  Attivita copyWith({
    String? titolo,
    String? descrizione,
    DateTime? orario,
    String? luogo,
    bool? completata,
    bool? generataDaIA,
    String? categoria,
    double? costoStimato,
    String? emozioni,
    String? immaginePath,
  }) {
    final newOrario = orario ?? this.orario;
    return Attivita(
      id: id,
      titolo: titolo ?? this.titolo,
      descrizione: descrizione ?? this.descrizione,
      orario: newOrario,
      luogo: luogo ?? this.luogo,
      completata: completata ?? this.completata,
      generataDaIA: generataDaIA ?? this.generataDaIA,
      categoria: categoria ?? this.categoria,
      costoStimato: costoStimato ?? this.costoStimato,
      emozioni: emozioni ?? this.emozioni,
      immaginePath: immaginePath ?? this.immaginePath,
    );
  }
}

