import 'package:flutter/material.dart';
import '../../models/viaggio.dart';
import 'mock_diary.dart';
import 'diary_card.dart';
import 'world_map_visited.dart';
import 'travel_level_badge.dart';

class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedViaggi = mockViaggi
        .where((viaggio) => viaggio.archiviato == true)
        .toList()
      ..sort((a, b) => b.dataInizio.compareTo(a.dataInizio));

    final giorniTotali = sortedViaggi.fold<int>(
      0,
      (totale, viaggio) => totale + viaggio.dataFine.difference(viaggio.dataInizio).inDays,
    );

    final kmStimati = sortedViaggi.length * 1000; // semplificato
    final paesiVisitati = sortedViaggi.map((v) => v.destinazione.toLowerCase()).toSet().length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Diario di Viaggio'),
        backgroundColor: Colors.indigo.shade400,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: sortedViaggi.isEmpty
          ? Center(
              child: Text(
                'Nessun viaggio archiviato ancora!',
                style: theme.textTheme.titleMedium,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // BADGE con progresso
                  TravelLevelBadge(paesiVisitati: paesiVisitati),

                  const SizedBox(height: 24),

                  // STATISTICHE
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat('Giorni', giorniTotali.toString()),
                          _verticalDivider(),
                          _buildStat('Km Stimati', kmStimati.toString()),
                          _verticalDivider(),
                          _buildStat('Paesi', paesiVisitati.toString()),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // MAPPA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: WorldMapVisited(viaggi: sortedViaggi),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // LISTA DEI VIAGGI
                  ListView.builder(
                    itemCount: sortedViaggi.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final viaggio = sortedViaggi[index];
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: DiaryCard(viaggio: viaggio),
                          ),
                          if (index != sortedViaggi.length - 1)
                            const Divider(thickness: 0.5, indent: 16, endIndent: 16),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E3A59),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 32,
      width: 1,
      color: Colors.grey.shade300,
    );
  }
}


