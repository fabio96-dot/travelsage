import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:travel_sage/providers/attivita_notifier.dart';
import '../../models/viaggio.dart';
import 'aggiungi_attivita_page.dart';
import '../../providers/attivita_provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';


extension StringCasingExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}

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
                            style: TextStyle(color: color.shade700, fontWeight: FontWeight.w500),
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
            await ref.read(attivitaNotifierProvider.notifier).aggiungiAttivita(userId: viaggio.userId,
            viaggioId: viaggio.id,
            attivita: nuova,);
            // Mostra un messaggio di successo);

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
        label: const Text("Aggiungi attività"),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, WidgetRef ref, Attivita att, int index, String orario) {
    final costo = att.costoStimato != null ? '€${att.costoStimato!.toStringAsFixed(2)}' : 'N/A';
    final categoria = att.categoria.isNotEmpty ? att.categoria.capitalize() : 'Attività';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(att.titolo)),
                if (att.generataDaIA)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Tooltip(
                      message: 'Generata dall’assistente AI',
                      child: Icon(Icons.smart_toy, size: 18, color: Colors.deepPurple),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '💶 $costo   •   🏷️ $categoria',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        subtitle: Text('$orario - ${att.luogo ?? "Nessun luogo"}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
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
                  await ref.read(attivitaNotifierProvider.notifier).modificaAttivita(userId: viaggio.userId, viaggioId: viaggio.id, attivita: modificata);;
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
              icon: const Icon(Icons.delete, size: 20),
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
                        child: const Text('Elimina', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (conferma == true) {
                  await ref.read(attivitaNotifierProvider.notifier).rimuoviAttivita(userId: viaggio.userId, viaggioId: viaggio.id, attivita: att);;
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
      ),
    );
  }
}
