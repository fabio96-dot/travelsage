import 'package:flutter_riverpod/flutter_riverpod.dart';

final usaIAProvider = StateProvider<bool>((ref) => true);
final mezzoTrasportoProvider = StateProvider<String>((ref) => 'Aereo');
final attivitaGiornaliereProvider = StateProvider<int>((ref) => 3);
final raggioKmProvider = StateProvider<double>((ref) => 10);
final interessiProvider = StateProvider<List<String>>((ref) => []);
final partecipantiProvider = StateProvider<List<String>>((ref) => []);
final etaMediaProvider = StateProvider<double>((ref) => 30);

/// Provider per la tipologia di viaggiatore selezionata (Backpacker, Luxury, ecc.)
final tipologiaViaggiatoreProvider = StateProvider<String>((ref) => 'Backpacker');

final startDateProvider = StateProvider<DateTime?>((ref) => null);
final endDateProvider = StateProvider<DateTime?>((ref) => null);
