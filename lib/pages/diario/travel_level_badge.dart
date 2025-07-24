import 'package:flutter/material.dart';
import 'trophy_board_page.dart';

class TravelLevel {
  final int min;
  final String titolo;
  final String icona;
  final Color colore;
  final String descrizione;

  TravelLevel(this.min, this.titolo, this.icona, this.colore, this.descrizione);
}

final livelli = [
  TravelLevel(0, 'Esploratore Novizio', '🐣', Colors.brown.shade300, 'Hai iniziato il tuo viaggio!'),
  TravelLevel(3, 'Viaggiatore Curioso', '🎒', Colors.orange, 'Hai visitato 3 paesi.'),
  TravelLevel(5, 'Globetrotter In Erba', '🌍', Colors.amber, 'Hai cominciato a esplorare il mondo!'),
  TravelLevel(7, 'Avventuriero', '🧭', Colors.lime, 'Hai sete di avventure!'),
  TravelLevel(10, 'Vagabondo Esperto', '🧳', Colors.teal, 'Esperto di viaggi!'),
  TravelLevel(15, 'Nomade Digitale', '💻', Colors.cyan, 'Vivi viaggiando e lavorando!'),
  TravelLevel(20, 'Viaggiatore Incallito', '✈️', Colors.blue, 'Non puoi più farne a meno.'),
  TravelLevel(25, 'Globe Trotter', '🌐', Colors.deepPurple, 'Ormai sei ovunque.'),
  TravelLevel(30, 'Leggenda dei Viaggi', '🏆', Colors.orange.shade700, 'Hai lasciato il segno.'),
  TravelLevel(40, 'Mito Universale', '💫', Colors.pinkAccent, 'Sei una leggenda dei cieli!'),
];

class TravelLevelBadge extends StatelessWidget {
  final int paesiVisitati;

  const TravelLevelBadge({super.key, required this.paesiVisitati});

  TravelLevel getLivello() {
    return livelli.lastWhere((lvl) => paesiVisitati >= lvl.min, orElse: () => livelli.first);
  }

  TravelLevel? getProssimoLivello() {
    for (var lvl in livelli) {
      if (paesiVisitati < lvl.min) return lvl;
    }
    return null;
  }

  List<TravelLevel> getBadgeSbloccati() {
    return livelli.where((lvl) => paesiVisitati >= lvl.min).toList();
  }

  @override
  Widget build(BuildContext context) {
    final livelloCorrente = getLivello();
    final prossimoLivello = getProssimoLivello();
    final sbloccati = getBadgeSbloccati();

    double progresso = 1.0;
    if (prossimoLivello != null) {
      final range = prossimoLivello.min - livelloCorrente.min;
      final attualiNelRange = paesiVisitati - livelloCorrente.min;
      progresso = attualiNelRange / range;
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrophyBoardPage(paesiVisitati: paesiVisitati),
              ),
            );
          },
          child: Tooltip(
            message: livelloCorrente.descrizione,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    livelloCorrente.colore.withOpacity(0.5),
                    livelloCorrente.colore,
                  ],
                  center: Alignment.topLeft,
                  radius: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: livelloCorrente.colore.withOpacity(0.6),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Text(
                livelloCorrente.icona,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        Text(
          livelloCorrente.titolo,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: livelloCorrente.colore,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progresso.clamp(0, 1),
                strokeWidth: 8,
                color: livelloCorrente.colore,
                backgroundColor: Colors.grey.shade300,
              ),
              Text(
                '$paesiVisitati',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: livelloCorrente.colore,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (prossimoLivello != null)
          Text(
            '🎯 Mancano ${prossimoLivello.min - paesiVisitati} paesi per "${prossimoLivello.titolo}"!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          )
        else
          const Text(
            '🚀 Hai raggiunto il livello massimo!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        const SizedBox(height: 12),
        Text('🎖 Badge sbloccati:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: sbloccati.map((badge) {
            return Chip(
              avatar: Text(badge.icona, style: const TextStyle(fontSize: 16)),
              label: Text(badge.titolo, style: const TextStyle(fontSize: 13)),
              backgroundColor: badge.colore.withOpacity(0.2),
              labelStyle: TextStyle(color: badge.colore),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: badge.colore.withOpacity(0.5)),
              ),
            );
          }).toList(),
        )
      ],
    );
  }
}

