import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/viaggio.dart';

final attivitaDelGiornoProvider = StreamProvider.family<List<Attivita>, ({String userId, String viaggioId, DateTime giorno})>((ref, args) {
  final giornoStr = DateFormat('yyyy-MM-dd').format(args.giorno);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(args.userId)
      .collection('viaggi')
      .doc(args.viaggioId)
      .collection('attivita')
      .where('giorno', isEqualTo: giornoStr)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => Attivita.fromJson(doc.data())).toList();
      });
});
