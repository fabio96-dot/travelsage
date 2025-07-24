import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/viaggio.dart';
import '../diario/world_map_visited.dart';
import '../diario/travel_level_badge.dart';
import '../diario/diary_card.dart';

class UserJournalPage extends StatefulWidget {
  final String userId;
  final String username;

  const UserJournalPage({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<UserJournalPage> createState() => _UserJournalPageState();
}

class _UserJournalPageState extends State<UserJournalPage> {
  List<Viaggio> viaggi = [];
  bool loading = true;
  int? _filtroAnno;
  String? immagineProfiloUrl;

  @override
  void initState() {
    super.initState();
    _loadViaggi();
    _loadProfileImage();
  }

  Future<void> _loadViaggi() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('viaggi')
        .where('uid', isEqualTo: widget.userId)
        .where('archiviato', isEqualTo: true)
        .get();

    setState(() {
      viaggi = snapshot.docs
          .map((doc) => Viaggio.fromFirestore(doc))
          .whereType<Viaggio>()
          .toList()
        ..sort((a, b) => b.dataInizio.compareTo(a.dataInizio));
      loading = false;
    });
  }

  Future<void> _loadProfileImage() async {
    final doc = await FirebaseFirestore.instance.collection('utenti').doc(widget.userId).get();
    if (doc.exists) {
      setState(() {
        immagineProfiloUrl = doc['immagineUrl'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 800;

    final viaggiFiltrati = _filtroAnno == null
        ? viaggi
        : viaggi.where((v) => v.dataInizio.year == _filtroAnno).toList();

    final giorniTotali = viaggiFiltrati.fold<int>(
      0,
      (totale, viaggio) => totale + viaggio.dataFine.difference(viaggio.dataInizio).inDays,
    );
    final kmStimati = viaggiFiltrati.length * 1000;
    final paesiVisitati = viaggiFiltrati.map((v) => v.destinazione.toLowerCase()).toSet().length;

    return Scaffold(
      appBar: AppBar(
        title: Text("Diario di ${widget.username}"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : viaggi.isEmpty
              ? Center(
                  child: Text(
                    'Questo utente non ha ancora viaggi archiviati.',
                    style: theme.textTheme.titleMedium,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      // 👤 FOTO PROFILO + NOME
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: immagineProfiloUrl != null
                            ? NetworkImage(immagineProfiloUrl!)
                            : null,
                        backgroundColor: Colors.grey.shade300,
                        child: immagineProfiloUrl == null
                            ? Icon(Icons.person, size: 48, color: Colors.grey.shade700)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.username,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),

                      TravelLevelBadge(paesiVisitati: paesiVisitati),
                      const SizedBox(height: 24),
                      _buildStatBox(theme, giorniTotali, kmStimati, paesiVisitati),
                      const SizedBox(height: 24),

                      // 🗺️ MAPPA
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

                      // 🔎 FILTRO ANNO
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
                                ...viaggi
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

                      // 📃 LISTA VIAGGI
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
                                    onDelete: null,
                                    onShare: null,
                                    onTap: () {},
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
                                  return DiaryCard(
                                    viaggio: viaggio,
                                    onDelete: null,
                                    onShare: null,
                                    onTap: () {},
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatBox(ThemeData theme, int giorni, int km, int paesi) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem('Giorni', giorni.toString()),
            _buildStatItem('Km Stimati', km.toString()),
            _buildStatItem('Paesi', paesi.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

