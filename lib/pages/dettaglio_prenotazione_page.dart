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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TITOLO
            Text(
              prenotazione.titolo,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              prenotazione.categoria,
              style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // CARD DATI
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.calendar_today, dataFormatted, theme),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.place, prenotazione.luogo, theme),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.attach_money, costoFormatted, theme),
                    if (prenotazione.codicePrenotazione != null &&
                        prenotazione.codicePrenotazione!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.confirmation_number, "Codice: ${prenotazione.codicePrenotazione!}", theme),
                    ],
                  ],
                ),
              ),
            ),

            // DESCRIZIONE
            if (prenotazione.descrizione != null && prenotazione.descrizione!.trim().isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Note o descrizione',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                prenotazione.descrizione!,
                style: theme.textTheme.bodyMedium,
              ),
            ],

            // LINK
            if (prenotazione.link != null && prenotazione.link!.trim().isNotEmpty) ...[
              const SizedBox(height: 30),
              Center(
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String testo, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            testo,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
