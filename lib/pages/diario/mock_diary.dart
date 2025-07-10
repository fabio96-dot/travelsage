import '../../models/viaggio.dart';

final mockViaggi = [
  Viaggio(
    destinazione: 'Tokyo',
    dataInizio: DateTime(2024, 4, 10),
    dataFine: DateTime(2024, 6, 18),
    budget: '1800',
    partecipanti: ['Luca', 'Anna'],
    confermato: true,
    archiviato: true,
  ),
  Viaggio(
    destinazione: 'Barcellona',
    dataInizio: DateTime(2023, 9, 3),
    dataFine: DateTime(2023, 9, 8),
    budget: '950',
    partecipanti: ['Marco', 'Sara', 'Teo'],
    confermato: true,
    archiviato: true,
  ),
];
