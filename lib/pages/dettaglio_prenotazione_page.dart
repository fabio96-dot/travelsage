import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/prenotazione.dart';

class DettaglioPrenotazionePage extends StatelessWidget {
  final Prenotazione prenotazione;

  const DettaglioPrenotazionePage({super.key, required this.prenotazione});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final costoFormatted = prenotazione.costo != null
        ? '€${prenotazione.costo!.toStringAsFixed(2)}'
        : 'Non specificato';
    final dataFormatted = DateFormat('EEEE dd MMMM yyyy', 'it_IT').format(prenotazione.data);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio Prenotazione'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (prenotazione.immagineUrl != null && prenotazione.immagineUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                prenotazione.immagineUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            prenotazione.titolo,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today, dataFormatted, theme),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.place, prenotazione.luogo, theme),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.attach_money, costoFormatted, theme),
          const SizedBox(height: 24),
          if (prenotazione.link != null && prenotazione.link!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text("Apri link prenotazione"),
                onPressed: () async {
                  final uri = Uri.tryParse(prenotazione.link!.trim());
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Link non valido o impossibile da aprire"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String testo, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            testo,
            style: TextTheme().bodyMedium,
          ),
        ),
      ],
    );
  }
}
