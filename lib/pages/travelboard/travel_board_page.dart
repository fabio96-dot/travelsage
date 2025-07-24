import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post_viaggio.dart';
import '../../providers/post_viaggio_provider.dart';
import 'package:intl/intl.dart';
import '../diario/Diary_page.dart';

class TravelBoardPage extends ConsumerWidget {
  const TravelBoardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final postsAsync = ref.watch(travelBoardPostsProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌍 Travel Board'),
        centerTitle: true,
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Errore: $err')),
        data: (posts) => posts.isEmpty
            ? Center(child: Text("Nessun post ancora pubblicato 🗺️", style: theme.textTheme.titleMedium))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _buildPostCard(context, theme, screenWidth, post);
                },
              ),
      ),
    );
  }

  Widget _buildPostCard(
    BuildContext context,
    ThemeData theme,
    double screenWidth,
    PostViaggio post,
  ) {
    final formatter = DateFormat('d MMM yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              post.immagineUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.image_not_supported)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.titolo, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(post.destinazione, style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_month, size: 18, color: theme.primaryColor),
                    const SizedBox(width: 4),
                    Text("${formatter.format(post.dataInizio)} - ${formatter.format(post.dataFine)}"),
                    const Spacer(),
                    Icon(Icons.euro, size: 18, color: theme.primaryColor),
                    const SizedBox(width: 4),
                    Text(post.costoTotaleStimato.toStringAsFixed(0)),
                  ],
                ),
                const SizedBox(height: 12),
                if (post.pensiero.isNotEmpty)
                  Text('"${post.pensiero}"', style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // ⭐ Rating (a sinistra)
                    Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                    const SizedBox(width: 4),
                    Text(post.valutazione.toStringAsFixed(1)),

                    const Spacer(),

                    // 👤 Utente (avatar + nome)
                    GestureDetector(
                      onTap: () {
                        final currentUid = FirebaseAuth.instance.currentUser?.uid;

                        if (post.userId == currentUid) {
                          // 🔁 Sei tu → vai alla tua DiaryPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DiaryPage()),
                          );
                        } else {
                          // 👤 Altro utente → vai alla sua pagina in sola lettura
                        if (post.userId.isNotEmpty && post.nomeUtente.isNotEmpty) {
                          Navigator.pushNamed(
                            context,
                            '/user-journal',
                            arguments: {
                              'userId': post.userId,
                              'username': post.nomeUtente,
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dati utente non disponibili')),
                          );
                        }
                        }
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: post.fotoProfiloUrl != null && post.fotoProfiloUrl!.isNotEmpty
                                ? NetworkImage(post.fotoProfiloUrl!)
                                : null,
                            child: post.fotoProfiloUrl == null || post.fotoProfiloUrl!.isEmpty
                                ? const Icon(Icons.person, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Vai al diario di ${post.nomeUtente.split(' ').first}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 🗑️ Elimina (solo autore)
                    if (FirebaseAuth.instance.currentUser?.uid == post.userId)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Elimina post',
                        onPressed: () async {
                          final conferma = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Elimina post'),
                              content: const Text('Vuoi eliminare questo viaggio dal Travel Board?'),
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
                            await FirebaseFirestore.instance
                                .collection('travel_board_posts')
                                .doc(post.id)
                                .delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Post eliminato con successo')),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

