import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/viaggio.dart';
import 'diary_card.dart';
import 'world_map_visited.dart';
import '../viaggio_dettaglio_page.dart';
import 'travel_level_badge.dart';
import '../../providers/travel_provider.dart';

final viaggiArchiviatiProvider = Provider<List<Viaggio>>((ref) {
  final statoViaggi = ref.watch(travelProvider);
  return statoViaggi.viaggi.where((v) => v.archiviato).toList();
});

class DiaryPage extends ConsumerStatefulWidget {
  const DiaryPage({super.key});

  @override
  ConsumerState<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends ConsumerState<DiaryPage> {
  int? _filtroAnno; // null = tutti
  void _showDeleteDialog(Viaggio viaggio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina viaggio'),
        content: const Text('Sei sicuro di voler eliminare questo viaggio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(travelProvider.notifier).rimuoviViaggio(viaggio.id);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
                  );
                }
              }
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(ThemeData theme, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider(ThemeData theme) {
    return Container(
      height: 32,
      width: 1,
      color: theme.dividerColor,
    );
  }

@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final screenWidth = MediaQuery.of(context).size.width;
  final isWideScreen = screenWidth > 800;

  final sortedViaggi = [...ref.watch(viaggiArchiviatiProvider)]
    ..sort((a, b) => b.dataInizio.compareTo(a.dataInizio));

  // 🔍 Filtro viaggi
  final viaggiFiltrati = _filtroAnno == null
      ? sortedViaggi
      : sortedViaggi.where((v) => v.dataInizio.year == _filtroAnno).toList();

  final giorniTotali = viaggiFiltrati.fold<int>(
    0,
    (totale, viaggio) =>
        totale + viaggio.dataFine.difference(viaggio.dataInizio).inDays,
  );
  final kmStimati = viaggiFiltrati.length * 1000;
  final paesiVisitati =
      viaggiFiltrati.map((v) => v.destinazione.toLowerCase()).toSet().length;

  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,
    appBar: AppBar(
      title: const Text('Diario di Viaggio'),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
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
                TravelLevelBadge(paesiVisitati: paesiVisitati),
                const SizedBox(height: 24),

                // Box statistiche
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: _buildStat(theme, 'Giorni', giorniTotali.toString())),
                        _verticalDivider(theme),
                        Expanded(child: _buildStat(theme, 'Km Stimati', kmStimati.toString())),
                        _verticalDivider(theme),
                        Expanded(child: _buildStat(theme, 'Paesi', paesiVisitati.toString())),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Mappa
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: WorldMapVisited(viaggi: viaggiFiltrati),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Filtro anno
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Filtro anno:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      DropdownButton<int?>(
                        value: _filtroAnno,
                        hint: const Text('Tutti'),
                        onChanged: (val) => setState(() => _filtroAnno = val),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('Tutti')),
                          ...sortedViaggi
                              .map((v) => v.dataInizio.year)
                              .toSet()
                              .toList()
                              .reversed
                              .map((anno) => DropdownMenuItem<int?>(value: anno, child: Text(anno.toString())))
                              .toList(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card viaggi archiviati (grid o lista)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: isWideScreen
                      ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: viaggiFiltrati.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 4 / 3,
                          ),
                          itemBuilder: (context, index) {
                            final viaggio = viaggiFiltrati[index];
                            return DiaryCard(
                              viaggio: viaggio,
                              onDelete: () => _showDeleteDialog(viaggio),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ViaggioDettaglioPage(viaggio: viaggio, index: index),
                                  ),
                                );
                              },
                            );
                          },
                        )
                      : ListView.separated(
                          itemCount: viaggiFiltrati.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          separatorBuilder: (context, index) => Divider(
                            thickness: 0.5,
                            indent: 16,
                            endIndent: 16,
                            color: theme.dividerColor,
                          ),
                          itemBuilder: (context, index) {
                            final viaggio = viaggiFiltrati[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              child: DiaryCard(
                                viaggio: viaggio,
                                onDelete: () => _showDeleteDialog(viaggio),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ViaggioDettaglioPage(viaggio: viaggio, index: index),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
  );
}
}