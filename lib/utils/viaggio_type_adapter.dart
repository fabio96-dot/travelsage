import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_sage/models/viaggio.dart';

part 'viaggio_type_adapter.g.dart';

@HiveType(typeId: 1)
class HiveAttivita extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String titolo;

  @HiveField(2)
  String descrizione;

  @HiveField(3)
  String orarioIso;

  @HiveField(4)
  String? luogo;

  @HiveField(5)
  bool completata;

  @HiveField(6)
  bool generataDaIA;

  @HiveField(7)
  String categoria;

  @HiveField(8)
  double? costoStimato;

  @HiveField(9)
  String? emozioni;

  @HiveField(10)
  String? immaginePath;

  HiveAttivita({
    required this.id,
    required this.titolo,
    required this.descrizione,
    required this.orarioIso,
    this.luogo,
    this.completata = false,
    this.generataDaIA = false,
    this.categoria = 'attivita',
    this.costoStimato = 0.0,
    this.emozioni,
    this.immaginePath,
  });

  factory HiveAttivita.fromModel(Attivita a) => HiveAttivita(
        id: a.id,
        titolo: a.titolo,
        descrizione: a.descrizione,
        orarioIso: a.orario.toIso8601String(),
        luogo: a.luogo,
        completata: a.completata,
        generataDaIA: a.generataDaIA,
        categoria: a.categoria,
        costoStimato: a.costoStimato,
        emozioni: a.emozioni,
        immaginePath: a.immaginePath,
      );

  Attivita toModel() => Attivita(
        id: id,
        titolo: titolo,
        descrizione: descrizione,
        orario: DateTime.parse(orarioIso),
        luogo: luogo,
        completata: completata,
        generataDaIA: generataDaIA,
        categoria: categoria,
        costoStimato: costoStimato,
        emozioni: emozioni,
        immaginePath: immaginePath,
      );
}

@HiveType(typeId: 2)
class HiveViaggio extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String titolo;

  @HiveField(2)
  String partenza;

  @HiveField(3)
  String destinazione;

  @HiveField(4)
  String dataInizio;

  @HiveField(5)
  String dataFine;

  @HiveField(6)
  String budget;

  @HiveField(7)
  List<String> partecipanti;

  @HiveField(8)
  bool confermato;

  @HiveField(9)
  bool archiviato;

  @HiveField(10)
  String? note;

  @HiveField(11)
  List<String> interessi;

  @HiveField(12)
  String mezzoTrasporto;

  @HiveField(13)
  int attivitaGiornaliere;

  @HiveField(14)
  double raggioKm;

  @HiveField(15)
  double etaMedia;

  @HiveField(16)
  String tipologiaViaggiatore;

  @HiveField(17)
  String? immagineUrl;

  @HiveField(18)
  double? lat;

  @HiveField(19)
  double? lng;

  @HiveField(20)
  Map<String, List<HiveAttivita>> itinerario;

  HiveViaggio({
    required this.id,
    required this.titolo,
    required this.partenza,
    required this.destinazione,
    required this.dataInizio,
    required this.dataFine,
    required this.budget,
    required this.partecipanti,
    required this.confermato,
    required this.archiviato,
    required this.interessi,
    required this.mezzoTrasporto,
    required this.attivitaGiornaliere,
    required this.raggioKm,
    required this.etaMedia,
    required this.tipologiaViaggiatore,
    this.note,
    this.immagineUrl,
    this.lat,
    this.lng,
    required this.itinerario,
  });

  factory HiveViaggio.fromModel(Viaggio v) => HiveViaggio(
        id: v.id,
        titolo: v.titolo,
        partenza: v.partenza,
        destinazione: v.destinazione,
        dataInizio: v.dataInizio.toIso8601String(),
        dataFine: v.dataFine.toIso8601String(),
        budget: v.budget,
        partecipanti: v.partecipanti,
        confermato: v.confermato,
        archiviato: v.archiviato,
        note: v.note,
        interessi: v.interessi,
        mezzoTrasporto: v.mezzoTrasporto,
        attivitaGiornaliere: v.attivitaGiornaliere,
        raggioKm: v.raggioKm,
        etaMedia: v.etaMedia,
        tipologiaViaggiatore: v.tipologiaViaggiatore,
        immagineUrl: v.immagineUrl,
        lat: v.coordinate?.latitude,
        lng: v.coordinate?.longitude,
        itinerario: v.itinerario.map(
          (k, v) => MapEntry(k, v.map((a) => HiveAttivita.fromModel(a)).toList()),
        ),
      );

  Viaggio toModel(String userId) => Viaggio(
        userId: userId,
        id: id,
        titolo: titolo,
        partenza: partenza,
        destinazione: destinazione,
        dataInizio: DateTime.parse(dataInizio),
        dataFine: DateTime.parse(dataFine),
        budget: budget,
        partecipanti: partecipanti,
        confermato: confermato,
        archiviato: archiviato,
        note: note,
        interessi: interessi,
        mezzoTrasporto: mezzoTrasporto,
        attivitaGiornaliere: attivitaGiornaliere,
        raggioKm: raggioKm,
        etaMedia: etaMedia,
        tipologiaViaggiatore: tipologiaViaggiatore,
        immagineUrl: immagineUrl,
        coordinate: lat != null && lng != null ? LatLng(lat!, lng!) : null,
        itinerario: itinerario.map(
          (k, v) => MapEntry(k, v.map((a) => a.toModel()).toList()),
        ),
      );
} 
