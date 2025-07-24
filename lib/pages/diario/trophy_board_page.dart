import 'package:flutter/material.dart';
import 'travel_level_badge.dart'; // contiene `livelli` e `TravelLevel`

class TrophyBoardPage extends StatelessWidget {
  final int paesiVisitati;

  const TrophyBoardPage({super.key, required this.paesiVisitati});

  bool isUnlocked(TravelLevel level) => paesiVisitati >= level.min;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bacheca Trofei'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: livelli.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final livello = livelli[index];
            final unlocked = isUnlocked(livello);

            final bgColor = unlocked
                ? livello.colore.withOpacity(0.15)
                : Colors.grey.shade200;

            final borderColor = unlocked
                ? livello.colore
                : Colors.grey.shade400;

            final iconColor = unlocked
                ? livello.colore
                : Colors.grey;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    livello.icona,
                    style: TextStyle(fontSize: 36, color: iconColor),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    livello.titolo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: unlocked ? livello.colore : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    unlocked
                        ? livello.descrizione
                        : '🔒 Da sbloccare a ${livello.min} paesi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: unlocked ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
