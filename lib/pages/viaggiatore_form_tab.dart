import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import '../../providers/organize_trip_controller.dart';

class ViaggiatoreFormTab extends ConsumerWidget {
  final TextEditingController participantController;
  final double screenWidth;

  const ViaggiatoreFormTab({
    super.key,
    required this.participantController,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final etaMedia = ref.watch(etaMediaProvider);
    final tipoSelezionato = ref.watch(tipologiaViaggiatoreProvider);
    final interessiSelezionati = ref.watch(interessiProvider);
    final participants = ref.watch(partecipantiProvider);

    const List<String> interessiDisponibili = [
      'Cultura', 'Natura', 'Relax', 'Cibo', 'Sport', 'Storia', 'Arte', 'Nightlife'
    ];

        return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSlider(ref, 'Età media', etaMedia, 10, 100, etaMediaProvider),
        const SizedBox(height: 32),
        Text('Tipologia Viaggiatore', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildViaggiatoreIcon(ref, Icons.backpack, 'Backpacker', tipoSelezionato),
            _buildViaggiatoreIcon(ref, RemixIcons.diamond_fill, 'Luxury', tipoSelezionato),
            _buildViaggiatoreIcon(ref, Icons.family_restroom, 'Family', tipoSelezionato),
            _buildViaggiatoreIcon(ref, RemixIcons.computer_fill, 'Digital Nomad', tipoSelezionato),
            _buildViaggiatoreIcon(ref, RemixIcons.car_fill, 'Road Tripper', tipoSelezionato),
          ],
        ),
        const SizedBox(height: 32),
        Text('Interessi', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: interessiDisponibili.map((interesse) => FilterChip(
            label: Text(interesse, style: TextStyle(fontSize: screenWidth < 400 ? 12 : 14)),
            selected: interessiSelezionati.contains(interesse),
            onSelected: (selected) {
              final list = [...interessiSelezionati];
              if (selected && !list.contains(interesse)) {
                list.add(interesse);
              } else if (!selected) {
                list.remove(interesse);
              }
              ref.read(interessiProvider.notifier).state = list;
            },
          )).toList(),
        ),
        const SizedBox(height: 32),
        Text('Partecipanti', style: theme.textTheme.titleMedium),
        Wrap(
          spacing: 8,
          children: participants.map((p) => Chip(
            label: Text(p),
            onDeleted: () {
              final updated = [...participants]..remove(p);
              ref.read(partecipantiProvider.notifier).state = updated;
            },
          )).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: participantController,
                decoration: const InputDecoration(labelText: 'Aggiungi partecipante'),
                onSubmitted: (name) => _addParticipant(ref, name),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addParticipant(ref, participantController.text),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildSlider(
    WidgetRef ref,
    String label,
    double value,
    double min,
    double max,
    StateProvider<double> provider, {
    int? step,
  }) {
    final divisions = step != null ? ((max - min) / step).round() : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.round()}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.round().toString(),
          onChanged: (val) => ref.read(provider.notifier).state = val,
        ),
      ],
    );
  }

  Widget _buildViaggiatoreIcon(
    WidgetRef ref,
    IconData icon,
    String tipo,
    String tipoSelezionato,
  ) {
    final selected = tipoSelezionato == tipo;

    return Tooltip(
      message: tipo,
      child: GestureDetector(
        onTap: () => ref.read(tipologiaViaggiatoreProvider.notifier).state = tipo,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? Colors.indigo : Colors.grey[300],
            boxShadow: selected
                ? [BoxShadow(color: Colors.indigo.withOpacity(0.5), blurRadius: 8)]
                : [],
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: selected ? Colors.white : Colors.black54,
            size: screenWidth < 400 ? 24 : 28,
          ),
        ),
      ),
    );
  }

  void _addParticipant(WidgetRef ref, String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      final list = [...ref.read(partecipantiProvider)];
      if (!list.contains(trimmed)) {
        list.add(trimmed);
        ref.read(partecipantiProvider.notifier).state = list;
      }
      participantController.clear();
    }
  }
}
