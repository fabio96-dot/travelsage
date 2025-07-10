import 'package:flutter/material.dart';

class TravelLevelBadge extends StatelessWidget {
  final int paesiVisitati;

  const TravelLevelBadge({super.key, required this.paesiVisitati});

  @override
  Widget build(BuildContext context) {
    String livello;
    Color colore;
    double progresso; // da 0 a 1

    if (paesiVisitati >= 10) {
      livello = 'Platino';
      colore = Colors.blue.shade300;
      progresso = 1;
    } else if (paesiVisitati >= 6) {
      livello = 'Oro';
      colore = Colors.amber.shade700;
      progresso = (paesiVisitati - 6) / 4;
    } else if (paesiVisitati >= 3) {
      livello = 'Argento';
      colore = Colors.grey;
      progresso = (paesiVisitati - 3) / 3;
    } else {
      livello = 'Bronzo';
      colore = Colors.brown.shade400;
      progresso = paesiVisitati / 3;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          decoration: BoxDecoration(
            color: colore,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            'Livello: $livello',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            value: progresso.clamp(0, 1),
            backgroundColor: Colors.grey.shade300,
            color: colore,
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}
