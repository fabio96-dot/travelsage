import 'package:cloud_firestore/cloud_firestore.dart';

class PostViaggio {
  final String id;
  final String userId;
  final String nomeUtente;
  final String titolo;
  final String destinazione;
  final DateTime dataInizio;
  final DateTime dataFine;
  final double costoTotaleStimato;
  final String pensiero;
  final String immagineUrl;
  final double valutazione;
  final DateTime timestamp;
  final String? fotoProfiloUrl; // 👈 AGGIUNTO

  PostViaggio({
    required this.id,
    required this.userId,
    required this.nomeUtente,
    required this.titolo,
    required this.destinazione,
    required this.dataInizio,
    required this.dataFine,
    required this.costoTotaleStimato,
    required this.pensiero,
    required this.immagineUrl,
    required this.valutazione,
    required this.timestamp,
    this.fotoProfiloUrl, // 👈 AGGIUNTO
  });

  factory PostViaggio.fromMap(String id, Map<String, dynamic> data) {
    return PostViaggio(
      id: id,
      userId: data['userId'] ?? '',
      nomeUtente: data['nomeUtente'] ?? '',
      titolo: data['titolo'] ?? '',
      destinazione: data['destinazione'] ?? '',
      dataInizio: (data['dataInizio'] as Timestamp).toDate(),
      dataFine: (data['dataFine'] as Timestamp).toDate(),
      costoTotaleStimato: (data['costoTotaleStimato'] ?? 0).toDouble(),
      pensiero: data['pensiero'] ?? '',
      immagineUrl: data['immagineUrl'] ?? '',
      valutazione: (data['valutazione'] ?? 0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      fotoProfiloUrl: data['fotoProfiloUrl'], // 👈 AGGIUNTO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nomeUtente': nomeUtente,
      'titolo': titolo,
      'destinazione': destinazione,
      'dataInizio': Timestamp.fromDate(dataInizio),
      'dataFine': Timestamp.fromDate(dataFine),
      'costoTotaleStimato': costoTotaleStimato,
      'pensiero': pensiero,
      'immagineUrl': immagineUrl,
      'valutazione': valutazione,
      'timestamp': Timestamp.fromDate(timestamp),
      'fotoProfiloUrl': fotoProfiloUrl, // 👈 AGGIUNTO
    };
  }
}

