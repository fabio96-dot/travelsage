import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/viaggio.dart';
import '../utils/string_extensions.dart';

class DettaglioAttivitaPage extends StatelessWidget {
  final Attivita attivita;

  const DettaglioAttivitaPage({super.key, required this.attivita});


  void _openMap(BuildContext context, String luogo) async {
    final query = Uri.encodeComponent(luogo);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossibile aprire la mappa per "$luogo".'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orarioStr = DateFormat.Hm().format(attivita.orario);
    final categoria = attivita.categoria.isNotEmpty
        ? attivita.categoria.capitalize()
        : 'Attività';

    return Scaffold(
      appBar: AppBar(
        title: Text(attivita.titolo),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Immagine o placeholder
            if (attivita.immaginePath != null && attivita.immaginePath!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  attivita.immaginePath!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.photo, size: 80, color: Colors.grey.shade600),
              ),

            const SizedBox(height: 16),

            // Orario e luogo
            Row(
              children: [
                Icon(Icons.access_time, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(orarioStr),
                const SizedBox(width: 16),
                Icon(Icons.place, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(attivita.luogo ?? 'Nessun luogo')),
              ],
            ),

            const SizedBox(height: 12),

            // Categoria e costo stimato
            Text(
              '$categoria · €${attivita.costoStimato?.toStringAsFixed(2) ?? "N/A"}',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),

            // Descrizione
            Text(
              attivita.descrizione.isNotEmpty ? attivita.descrizione : 'Nessuna descrizione',
              style: theme.textTheme.bodyLarge,
            ),

            const SizedBox(height: 24),

            // Emozioni / Note personali
            Text(
              'Emozioni / Note',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              attivita.emozioni?.isNotEmpty == true ? attivita.emozioni! : 'Nessuna nota',
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 32),

            // Bottone Apri Mappa
            if ((attivita.luogo?.isNotEmpty ?? false))
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text('Apri Mappa'),
                  onPressed: () => _openMap(context, attivita.luogo!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
