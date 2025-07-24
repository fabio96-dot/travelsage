import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/viaggio.dart';
import '../../providers/spese_notifier.dart';
import '../../services/unsplash_api.dart';

class DiaryCard extends ConsumerWidget {
  final Viaggio viaggio;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onShare; // 👈 aggiunto

  const DiaryCard({
    super.key,
    required this.viaggio,
    required this.onDelete,
    required this.onTap,
    this.onShare, // 👈 aggiunto
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM/yyyy');
    final screenWidth = MediaQuery.of(context).size.width;

    final titolo = viaggio.titolo.trim().isNotEmpty
        ? viaggio.titolo.trim()
        : viaggio.destinazione.trim().isNotEmpty
            ? viaggio.destinazione.trim()
            : 'Senza Titolo';

    final dateRange =
        '${formatter.format(viaggio.dataInizio)} – ${formatter.format(viaggio.dataFine)}';

    final spese = ref.watch(speseProvider(viaggio.id));
    final totaleSpese = spese.fold<double>(0.0, (sum, s) => sum + s.importo);

    return FutureBuilder<String?>(
      future: ref.read(unsplashApiProvider).getImageForViaggio(viaggio),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data;

        return InkWell(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image_outlined, size: 40),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.photo_outlined, color: Colors.grey, size: 48),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Colors.indigo, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              titolo,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined, color: Colors.indigo),
                            onPressed: onShare,
                            tooltip: 'Condividi su Travelboard',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: onDelete,
                            tooltip: 'Elimina viaggio',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            dateRange,
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.euro, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Costo effettivo: €${totaleSpese.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}



