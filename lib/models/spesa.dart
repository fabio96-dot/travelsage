class Spesa {
  final String id; // Aggiunto ID per identificazione univoca
  final String descrizione;
  final double importo;
  final String pagatore;
  final List<String> coinvolti;
  final DateTime data;

  Spesa({
    required this.id, // Aggiunto come campo required
    required this.descrizione,
    required this.importo,
    required this.pagatore,
    required this.coinvolti,
    required this.data,
  });

  // Metodo factory per la deserializzazione da JSON
  factory Spesa.fromJson(Map<String, dynamic> json) {
    return Spesa(
      id: json['id'] ?? '', // Gestisci il caso in cui id sia null
      descrizione: json['descrizione'],
      importo: (json['importo'] as num).toDouble(), // Conversione sicura a double
      pagatore: json['pagatore'],
      coinvolti: List<String>.from(json['coinvolti'] ?? []), // Lista sicura
      data: DateTime.parse(json['data']), // Parsing della data da stringa
    );
  }

  // Metodo per la serializzazione a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descrizione': descrizione,
      'importo': importo,
      'pagatore': pagatore,
      'coinvolti': coinvolti,
      'data': data.toIso8601String(), // Conversione data a stringa ISO
    };
  }

  // Metodo copyWith per aggiornamenti immutabili
  Spesa copyWith({
    String? id,
    String? descrizione,
    double? importo,
    String? pagatore,
    List<String>? coinvolti,
    DateTime? data,
  }) {
    return Spesa(
      id: id ?? this.id,
      descrizione: descrizione ?? this.descrizione,
      importo: importo ?? this.importo,
      pagatore: pagatore ?? this.pagatore,
      coinvolti: coinvolti ?? List.from(this.coinvolti),
      data: data ?? this.data,
    );
  }
}
