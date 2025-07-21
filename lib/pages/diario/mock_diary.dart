import '../../models/viaggio.dart';

final mockViaggi = [
  Viaggio(
    userId: 'user123',
    id:"1",
    titolo: 'Viaggio a Tokyo',
    partenza: 'Roma',
    destinazione: 'Tokyo',
    dataInizio: DateTime(2024, 4, 10),
    dataFine: DateTime(2024, 6, 18),
    budget: '1800',
    partecipanti: ['Luca', 'Anna'],
    confermato: true,
    archiviato: true,
  ),
  Viaggio(
    userId: 'user456',
    id:"2",
    partenza: 'Milano',
    titolo: 'Viaggio a Barcellona',
    destinazione: 'Barcellona',
    dataInizio: DateTime(2023, 9, 3),
    dataFine: DateTime(2023, 9, 8),
    budget: '950',
    partecipanti: ['Marco', 'Sara', 'Teo'],
    confermato: true,
    archiviato: true,
  ),
];
