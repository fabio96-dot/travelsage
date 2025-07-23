import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_sage/providers/attivita_notifier.dart';
import '../../models/viaggio.dart';
import 'aggiungi_attivita_page.dart';
import '../../providers/attivita_provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../utils/string_extensions.dart';
import 'dettaglio_attivita_page.dart';


class GiornoItinerarioPage extends ConsumerWidget {
  final DateTime giorno;
  final Viaggio viaggio;

  const GiornoItinerarioPage({
    super.key,
    required this.giorno,
    required this.viaggio,
  });

  Map<String, double> calcolaCostiPerCategoria(List<Attivita> attivita) {
    final costi = <String, double>{};
    for (final a in attivita) {
      final cat = a.categoria.toLowerCase();
      final costo = a.costoStimato ?? 0.0;
      costi[cat] = (costi[cat] ?? 0.0) + costo;
    }
    return costi;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = DateFormat('EEEE d MMMM yyyy', 'it_IT').format(giorno);
    final theme = Theme.of(context);

    final asyncAttivita = ref.watch(attivitaDelGiornoProvider((
      giorno: giorno,
      userId: viaggio.userId, // 👈 se lo hai salvato
      viaggioId: viaggio.id,
    )));

    return Scaffold(
      appBar: AppBar(
        title: Text('Itinerario - $data'),
      ),
      body: asyncAttivita.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Errore: $err')),
        data: (attivita) {
          attivita.sort((a, b) => a.orario.compareTo(b.orario));
          final costi = calcolaCostiPerCategoria(attivita);

          final icons = {
            'pernottamento': Icons.hotel,
            'trasporto': Icons.directions_car,
            'attività': Icons.local_activity,
          };

          final colori = {
            'pernottamento': Colors.deepPurple,
            'trasporto': Colors.teal,
            'attività': Colors.orange,
          };

          final riassuntoCosti = Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Costi stimati del giorno",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: costi.entries.map((entry) {
                        final icon = icons[entry.key] ?? Icons.category;
                        final color = colori[entry.key] ?? Colors.grey;
                        return Chip(
                          backgroundColor: color.withOpacity(0.1),
                          avatar: Icon(icon, size: 18, color: color),
                          label: Text(
                            "${entry.key.capitalize()}: €${entry.value.toStringAsFixed(2)}",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: color.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
                            ),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.summarize, size: 18, color: Colors.black87),
                        const SizedBox(width: 6),
                        Text(
                          "Totale: €${costi.values.fold(0.0, (a, b) => a + b).toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );

          if (attivita.isEmpty) {
            return const Center(
              child: Text(
                'Non ci sono attività programmate.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            );
          }

          return Column(
            children: [
              riassuntoCosti,
              Expanded(
                child: AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: attivita.length,
                    itemBuilder: (context, index) {
                      final att = attivita[index];
                      final orario = DateFormat.Hm().format(att.orario);
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 400),
                        child: SlideAnimation(
                          verticalOffset: 40.0,
                          curve: Curves.easeOut,
                          child: FadeInAnimation(
                            child: _buildListItem(context, ref, att, index, orario),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final nuova = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AggiungiAttivitaPage(giorno: giorno, viaggio: viaggio),
            ),
          );

          if (nuova != null && nuova is Attivita) {
            await ref.read(attivitaNotifierProvider.notifier).aggiungiAttivita(
              userId: viaggio.userId,
              viaggioId: viaggio.id,
              attivita: nuova,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Attività aggiunta con successo!"),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Aggiungi"),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, WidgetRef ref, Attivita att, int index, String orario) {
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;
  final colorScheme = theme.colorScheme;

  final costo = att.costoStimato != null ? '€${att.costoStimato!.toStringAsFixed(2)}' : 'N/A';
  final categoria = att.categoria.isNotEmpty ? att.categoria.capitalize() : 'Attività';

  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DettaglioAttivitaPage(attivita: att),
        ),
      );
    },
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cerchio con numero attività
            CircleAvatar(
              backgroundColor: colorScheme.primary,
              radius: 18,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info attività (titolo, badge, dettagli)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titolo attività
                  Text(
                    att.titolo,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  // Badge AI sotto titolo
                  if (att.generataDaIA)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.smart_toy, size: 14, color: colorScheme.secondary),
                            const SizedBox(width: 4),
                            Text(
                              'AI',
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Categoria e costo
                  Text(
                    '$categoria · $costo',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),

                  // Orario e luogo
                  Text(
                    '$orario - ${att.luogo ?? "Nessun luogo"}',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Azioni: modifica / elimina (lascia come hai ora)
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, size: 20, color: colorScheme.primary),
                  onPressed: () async {
                    final modificata = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AggiungiAttivitaPage(
                          giorno: giorno,
                          viaggio: viaggio,
                          attivitaEsistente: att,
                        ),
                      ),
                    );
                    if (modificata != null && modificata is Attivita) {
                      await ref.read(attivitaNotifierProvider.notifier).modificaAttivita(
                        userId: viaggio.userId,
                        viaggioId: viaggio.id,
                        attivita: modificata,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Attività modificata con successo!"),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 20, color: colorScheme.error),
                  onPressed: () async {
                    final conferma = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Conferma eliminazione'),
                        content: const Text('Sei sicuro di voler eliminare questa attività?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Elimina', style: TextStyle(color: colorScheme.error)),
                          ),
                        ],
                      ),
                    );

                    if (conferma == true) {
                      await ref.read(attivitaNotifierProvider.notifier).rimuoviAttivita(
                        userId: viaggio.userId,
                        viaggioId: viaggio.id,
                        attivita: att,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Attività eliminata con successo!"),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}
