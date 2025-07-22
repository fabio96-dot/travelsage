import 'package:cloud_firestore/cloud_firestore.dart';

class Prenotazione {
  final String id;
  final String titolo;
  final String categoria;
  final DateTime data;
  final String luogo;
  final String? descrizione;
  final String? codicePrenotazione;
  final String? link;
  final String? immagineUrl;
  final double? costo;         // 💰 NUOVO campo

  Prenotazione({
    required this.id,
    required this.titolo,
    required this.categoria,
    required this.data,
    required this.luogo,
    this.descrizione,
    this.codicePrenotazione,
    this.link,
    this.immagineUrl,
    this.costo, // 💰 NUOVO campo
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titolo': titolo,
      'categoria': categoria,
      'data': data.toIso8601String(),
      'luogo': luogo,
      'descrizione': descrizione,
      'codicePrenotazione': codicePrenotazione,
      'link': link,
      'immagineUrl': immagineUrl,
      'costo': costo, // 💰 NUOVO campo
    };
  }

  factory Prenotazione.fromMap(Map<String, dynamic> map) {
    return Prenotazione(
      id: map['id'],
      titolo: map['titolo'],
      categoria: map['categoria'],
      data: DateTime.parse(map['data']),
      luogo: map['luogo'],
      descrizione: map['descrizione'],
      codicePrenotazione: map['codicePrenotazione'],
      link: map['link'],
      immagineUrl: map['immagineUrl'],
      costo: map['costo'] != null ? (map['costo'] as num).toDouble() : null, // 💰 NUOVO campo
    );
  }

  factory Prenotazione.fromFirestore(DocumentSnapshot doc) {
    return Prenotazione.fromMap(doc.data() as Map<String, dynamic>);
  }
}
