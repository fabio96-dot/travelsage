import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import '../../providers/organize_trip_controller.dart';
import '../../providers/dataselector.dart';

class ViaggioFormTab extends ConsumerWidget {
  final TextEditingController departureController;
  final TextEditingController destinationController;
  final TextEditingController budgetController;

  const ViaggioFormTab({
    super.key,
    required this.departureController,
    required this.destinationController,
    required this.budgetController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTextField('Partenza', Icons.flight_takeoff, departureController),
        const SizedBox(height: 16),
        _buildTextField('Destinazione', Icons.location_on_outlined, destinationController),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DateSelector(
                label: 'Data Inizio',
                selectedDate: ref.watch(startDateProvider),
                onDateSelected: (date) => ref.read(startDateProvider.notifier).state = date,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DateSelector(
                label: 'Data Fine',
                selectedDate: ref.watch(endDateProvider),
                initialDateFallback: ref.watch(startDateProvider),
                onDateSelected: (date) => ref.read(endDateProvider.notifier).state = date,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField('Budget per persona (€)', Icons.euro_outlined, budgetController, isNumeric: true),
        const SizedBox(height: 24),
        Text('Mezzo di trasporto', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _MezzoTrasportoSelector(screenWidth: screenWidth),
        const SizedBox(height: 24),
        const _AttivitaSlider(),
        const SizedBox(height: 8),
        const _RaggioSlider(),
        const SizedBox(height: 16),
        const _IASelector(),
      ],
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isNumeric = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      keyboardType: isNumeric ? TextInputType.number : null,
      validator: (val) => val == null || val.isEmpty ? 'Campo obbligatorio' : null,
    );
  }
}

// mezzi di trasporto

class _MezzoTrasportoSelector extends ConsumerWidget {
  final double screenWidth;

  const _MezzoTrasportoSelector({required this.screenWidth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMezzo = ref.watch(mezzoTrasportoProvider);

    const List<Map<String, dynamic>> mezziTrasporto = [
      {'nome': 'Aereo', 'icona': RemixIcons.plane_fill},
      {'nome': 'Auto', 'icona': RemixIcons.car_fill},
      {'nome': 'Moto', 'icona': RemixIcons.motorbike_fill},
      {'nome': 'Nave', 'icona': RemixIcons.ship_fill},
      {'nome': 'Camper', 'icona': RemixIcons.bus_2_fill},
      {'nome': 'Treno', 'icona': RemixIcons.train_fill},
    ];

    double responsiveIconSize(double width) {
      if (width < 400) return 24;
      if (width < 600) return 28;
      return 32;
    }

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 16,
      runSpacing: 12,
      children: mezziTrasporto.map((mezzo) {
        final nome = mezzo['nome']!;
        final icona = mezzo['icona'] as IconData;
        final selezionato = selectedMezzo == nome;
        return Tooltip(
          message: nome,
          child: GestureDetector(
            onTap: () => ref.read(mezzoTrasportoProvider.notifier).state = nome,
            child: CircleAvatar(
              radius: screenWidth < 400 ? 22 : 28,
              backgroundColor: selezionato ? Colors.indigo : Colors.grey[300],
              child: Icon(
                icona,
                size: responsiveIconSize(screenWidth),
                color: selezionato ? Colors.white : Colors.black54,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// slider per le attivita

class _AttivitaSlider extends ConsumerWidget {
  const _AttivitaSlider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valore = ref.watch(attivitaGiornaliereProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attività giornaliere: $valore'),
        Slider(
          value: valore.toDouble(),
          min: 1,
          max: 8,
          divisions: 7,
          onChanged: (val) =>
              ref.read(attivitaGiornaliereProvider.notifier).state = val.round(),
        ),
      ],
    );
  }
}

// slider per il raggio di azione

class _RaggioSlider extends ConsumerWidget {
  const _RaggioSlider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valore = ref.watch(raggioKmProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Raggio massimo (km): ${valore.round()}'),
        Slider(
          value: valore,
          min: 0,
          max: 500,
          divisions: 20,
          onChanged: (val) => ref.read(raggioKmProvider.notifier).state = val,
        ),
      ],
    );
  }
}


// selezione IA

class _IASelector extends ConsumerWidget {
  const _IASelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usaIA = ref.watch(usaIAProvider);

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Sfrutta l'assistente IA per generare l'itinerario", style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 4),
          const Icon(Icons.smart_toy_sharp, color: Colors.indigo),
        ],
      ),
      value: usaIA,
      onChanged: (val) => ref.read(usaIAProvider.notifier).state = val,
    );
  }
}
