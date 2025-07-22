import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/viaggio.dart';
import '../../models/prenotazione.dart';
import '../../providers/prenotazione_provider.dart';
import 'aggiungi_prenotazione_page.dart';
import 'dettaglio_prenotazione_page.dart';

class PrenotazioniTab extends ConsumerStatefulWidget {
  final Viaggio viaggio;

  const PrenotazioniTab({super.key, required this.viaggio});

  @override
  ConsumerState<PrenotazioniTab> createState() => _PrenotazioniTabState();
}

class _PrenotazioniTabState extends ConsumerState<PrenotazioniTab> {
  @override
  Widget build(BuildContext context) {
    final asyncPrenotazioni = ref.watch(prenotazioniProvider((
      userId: widget.viaggio.userId,
      viaggioId: widget.viaggio.id,
    )));

    return Scaffold(
      body: asyncPrenotazioni.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Errore: $e")),
        data: (prenotazioni) {
          if (prenotazioni.isEmpty) {
            return const Center(
              child: Text(
                'Nessuna prenotazione trovata',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            );
          }

          final prenotazioniPerCategoria = <String, List<Prenotazione>>{};
          for (var p in prenotazioni) {
            prenotazioniPerCategoria.putIfAbsent(p.categoria, () => []).add(p);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            children: prenotazioniPerCategoria.entries.map((entry) {
              return _buildCategoriaSection(entry.key, entry.value, context);
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final nuova = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AggiungiPrenotazionePage(viaggio: widget.viaggio),
            ),
          );

          if (nuova != null && nuova is Prenotazione) {
            await ref.read(prenotazioneNotifierProvider.notifier).aggiungiPrenotazione(
              viaggioId: widget.viaggio.id,
              prenotazione: nuova,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Prenotazione aggiunta con successo!"),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Aggiungi Prenotazione"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCategoriaSection(String categoria, List<Prenotazione> items, BuildContext context) {
    final icon = _iconaPerCategoria(categoria);
    final color = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              categoria.toUpperCase(),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((p) => _buildPrenotazioneCard(p, context, ref)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPrenotazioneCard(Prenotazione p, BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final costoFormatted = p.costo != null ? ' - €${p.costo!.toStringAsFixed(2)}' : '';
    final sottotitolo = '${DateFormat('dd/MM/yyyy').format(p.data)} - ${p.luogo}$costoFormatted';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DettaglioPrenotazionePage(prenotazione: p),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: p.immagineUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(p.immagineUrl!, width: 48, height: 48, fit: BoxFit.cover),
              )
            : const Icon(Icons.book_online, size: 32),
        title: Text(p.titolo, style: theme.textTheme.titleMedium),
        subtitle: Text(sottotitolo, style: theme.textTheme.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orangeAccent),
              tooltip: "Modifica",
              onPressed: () async {
                final modificata = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AggiungiPrenotazionePage(
                      viaggio: widget.viaggio,
                      prenotazione: p,
                    ),
                  ),
                );

                if (modificata != null && modificata is Prenotazione) {
                  await ref.read(prenotazioneNotifierProvider.notifier).modificaPrenotazione(
                        viaggioId: widget.viaggio.id,
                        prenotazione: modificata,
                      );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _confermaEliminazione(context, ref, p),
            ),
          ],
        ),
      ),
    );
  }


  IconData _iconaPerCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'alloggio':
        return Icons.hotel;
      case 'trasporto':
        return Icons.flight;
      case 'attività':
        return Icons.museum;
      default:
        return Icons.bookmark_border;
    }
  }

  void _confermaEliminazione(BuildContext context, WidgetRef ref, Prenotazione p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Elimina Prenotazione'),
        content: Text('Vuoi davvero eliminare "${p.titolo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await ref.read(prenotazioneNotifierProvider.notifier).eliminaPrenotazione(
                    viaggioId: widget.viaggio.id,
                    prenotazioneId: p.id,
                  );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Elimina'),
          )
        ],
      ),
    );
  }
}

