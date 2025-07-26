// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'viaggio_type_adapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveAttivitaAdapter extends TypeAdapter<HiveAttivita> {
  @override
  final int typeId = 1;

  @override
  HiveAttivita read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveAttivita(
      id: fields[0] as String,
      titolo: fields[1] as String,
      descrizione: fields[2] as String,
      orarioIso: fields[3] as String,
      luogo: fields[4] as String?,
      completata: fields[5] as bool,
      generataDaIA: fields[6] as bool,
      categoria: fields[7] as String,
      costoStimato: fields[8] as double?,
      emozioni: fields[9] as String?,
      immaginePath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveAttivita obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titolo)
      ..writeByte(2)
      ..write(obj.descrizione)
      ..writeByte(3)
      ..write(obj.orarioIso)
      ..writeByte(4)
      ..write(obj.luogo)
      ..writeByte(5)
      ..write(obj.completata)
      ..writeByte(6)
      ..write(obj.generataDaIA)
      ..writeByte(7)
      ..write(obj.categoria)
      ..writeByte(8)
      ..write(obj.costoStimato)
      ..writeByte(9)
      ..write(obj.emozioni)
      ..writeByte(10)
      ..write(obj.immaginePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveAttivitaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveViaggioAdapter extends TypeAdapter<HiveViaggio> {
  @override
  final int typeId = 2;

  @override
  HiveViaggio read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveViaggio(
      id: fields[0] as String,
      titolo: fields[1] as String,
      partenza: fields[2] as String,
      destinazione: fields[3] as String,
      dataInizio: fields[4] as String,
      dataFine: fields[5] as String,
      budget: fields[6] as String,
      partecipanti: (fields[7] as List).cast<String>(),
      confermato: fields[8] as bool,
      archiviato: fields[9] as bool,
      interessi: (fields[11] as List).cast<String>(),
      mezzoTrasporto: fields[12] as String,
      attivitaGiornaliere: fields[13] as int,
      raggioKm: fields[14] as double,
      etaMedia: fields[15] as double,
      tipologiaViaggiatore: fields[16] as String,
      note: fields[10] as String?,
      immagineUrl: fields[17] as String?,
      lat: fields[18] as double?,
      lng: fields[19] as double?,
      itinerario: (fields[20] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<HiveAttivita>())),
    );
  }

  @override
  void write(BinaryWriter writer, HiveViaggio obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titolo)
      ..writeByte(2)
      ..write(obj.partenza)
      ..writeByte(3)
      ..write(obj.destinazione)
      ..writeByte(4)
      ..write(obj.dataInizio)
      ..writeByte(5)
      ..write(obj.dataFine)
      ..writeByte(6)
      ..write(obj.budget)
      ..writeByte(7)
      ..write(obj.partecipanti)
      ..writeByte(8)
      ..write(obj.confermato)
      ..writeByte(9)
      ..write(obj.archiviato)
      ..writeByte(10)
      ..write(obj.note)
      ..writeByte(11)
      ..write(obj.interessi)
      ..writeByte(12)
      ..write(obj.mezzoTrasporto)
      ..writeByte(13)
      ..write(obj.attivitaGiornaliere)
      ..writeByte(14)
      ..write(obj.raggioKm)
      ..writeByte(15)
      ..write(obj.etaMedia)
      ..writeByte(16)
      ..write(obj.tipologiaViaggiatore)
      ..writeByte(17)
      ..write(obj.immagineUrl)
      ..writeByte(18)
      ..write(obj.lat)
      ..writeByte(19)
      ..write(obj.lng)
      ..writeByte(20)
      ..write(obj.itinerario);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveViaggioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
